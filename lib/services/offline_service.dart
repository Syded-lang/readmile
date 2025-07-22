import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/offline_book.dart';
import '../services/gridfs_service.dart';
import '../services/storage_service.dart';

class OfflineService {
  static final GridFSService _gridfsService = GridFSService();

  // Enhanced memory management
  static final Map<String, Uint8List> _epubCache = {};
  static final Map<String, Uint8List> _coverCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, int> _accessCounts = {};

  // Configuration
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB max
  static const int _maxCachedBooks = 10; // Max books in memory
  static const Duration _cacheExpiration = Duration(hours: 24);

  // Progress tracking
  static final Map<String, StreamController<double>> _progressControllers = {};

  /// Cache a book's content for offline reading with enhanced management
  static Future<bool> cacheBookForOffline(
      Book book, {
        Function(double)? onProgress,
        bool forceDownload = false,
      }) async {
    try {
      final String bookId = book.id;
      onProgress?.call(0.05);

      // Check if already cached and not forcing download
      if (!forceDownload && _epubCache.containsKey(bookId)) {
        print('📚 Book already cached: ${book.title}');
        _updateAccessStats(bookId);
        onProgress?.call(1.0);
        return true;
      }

      onProgress?.call(0.1);

      // Manage memory before downloading
      await _ensureMemoryCapacity(book);
      onProgress?.call(0.15);

      // Create progress stream for this download
      final progressController = StreamController<double>.broadcast();
      _progressControllers[bookId] = progressController;

      try {
        // Download EPUB and cover in parallel
        final downloadFutures = await Future.wait([
          _downloadWithProgress(
                () => _gridfsService.downloadFile(book.gridfsEpubId ?? ''),
            'EPUB',
            0.15,
            0.65,
            onProgress,
          ),
          _downloadWithProgress(
                () => _gridfsService.getCoverImage(book.coverUrl),
            'Cover',
            0.65,
            0.85,
            onProgress,
          ),
        ]);

        final epubBytes = downloadFutures[0] as Uint8List?;
        final coverBytes = downloadFutures[1] as Uint8List?;

        if (epubBytes == null || epubBytes.isEmpty) {
          print('❌ Failed to download EPUB for caching: ${book.title}');
          return false;
        }

        onProgress?.call(0.9);

        // Store in memory cache with metadata
        await _storeInCache(bookId, epubBytes, coverBytes);

        // Create and save cached book metadata
        final cachedBook = OfflineBook(
          bookId: bookId,
          title: book.title,
          author: book.author,
          localFilePath: '', // Memory-only cache
          coverPath: '',
          downloadDate: DateTime.now(),
          fileSizeBytes: epubBytes.length,
          categories: book.categories,
          isAvailable: true,
          lastAccessDate: DateTime.now(),
        );

        await StorageService.saveOfflineBook(cachedBook);
        onProgress?.call(1.0);

        final sizeStr = _formatBytes(epubBytes.length);
        print('✅ Successfully cached book: ${book.title} ($sizeStr in memory)');
        return true;

      } finally {
        // Clean up progress controller
        _progressControllers[bookId]?.close();
        _progressControllers.remove(bookId);
      }

    } catch (e) {
      print('❌ Error caching book for offline: $e');
      return false;
    }
  }

  /// Download with progress reporting
  static Future<Uint8List?> _downloadWithProgress(
      Future<Uint8List?> Function() downloadFunc,
      String type,
      double startProgress,
      double endProgress,
      Function(double)? onProgress,
      ) async {
    onProgress?.call(startProgress);
    final result = await downloadFunc();
    onProgress?.call(endProgress);
    return result;
  }

  /// Store data in cache with proper memory management
  static Future<void> _storeInCache(
      String bookId,
      Uint8List epubBytes,
      Uint8List? coverBytes,
      ) async {
    _epubCache[bookId] = epubBytes;
    _cacheTimestamps[bookId] = DateTime.now();
    _accessCounts[bookId] = 1;

    if (coverBytes != null && coverBytes.isNotEmpty) {
      _coverCache[bookId] = coverBytes;
    }

    // Trigger memory management if needed
    await _manageMemoryUsage();
  }

  /// Ensure we have enough memory capacity for new book
  static Future<void> _ensureMemoryCapacity(Book book) async {
    // Estimate book size (rough estimate if not known)
    final estimatedSize = 5 * 1024 * 1024; // 5MB average
    final currentUsage = _calculateTotalMemoryUsage();

    if (currentUsage + estimatedSize > _maxMemoryUsage ||
        _epubCache.length >= _maxCachedBooks) {
      await _evictLeastRecentlyUsed(1);
    }
  }

  /// Smart memory management with LRU eviction
  static Future<void> _manageMemoryUsage() async {
    final now = DateTime.now();

    // Remove expired entries
    final expiredKeys = <String>[];
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredKeys.add(key);
      }
    });

    for (String key in expiredKeys) {
      await _removeFromCache(key, updateStorage: true);
    }

    // Check memory limits
    while (_calculateTotalMemoryUsage() > _maxMemoryUsage ||
        _epubCache.length > _maxCachedBooks) {
      await _evictLeastRecentlyUsed(1);
    }
  }

  /// Evict least recently used books
  static Future<void> _evictLeastRecentlyUsed(int count) async {
    if (_epubCache.isEmpty) return;

    // Sort by access count and timestamp
    final sortedEntries = _cacheTimestamps.entries.toList();
    sortedEntries.sort((a, b) {
      final accessA = _accessCounts[a.key] ?? 0;
      final accessB = _accessCounts[b.key] ?? 0;

      if (accessA != accessB) {
        return accessA.compareTo(accessB); // Lower access count first
      }
      return a.value.compareTo(b.value); // Older timestamp first
    });

    for (int i = 0; i < count && i < sortedEntries.length; i++) {
      final bookId = sortedEntries[i].key;
      print('🗑️ Evicting cached book: $bookId');
      await _removeFromCache(bookId, updateStorage: true);
    }
  }

  /// Remove book from cache
  static Future<void> _removeFromCache(String bookId, {bool updateStorage = false}) async {
    _epubCache.remove(bookId);
    _coverCache.remove(bookId);
    _cacheTimestamps.remove(bookId);
    _accessCounts.remove(bookId);

    if (updateStorage) {
      await StorageService.removeOfflineBook(bookId);
    }
  }

  /// Update access statistics
  static void _updateAccessStats(String bookId) {
    _cacheTimestamps[bookId] = DateTime.now();
    _accessCounts[bookId] = (_accessCounts[bookId] ?? 0) + 1;
  }

  /// Get cached EPUB content from memory
  static Uint8List? getCachedEpubContent(String bookId) {
    if (_epubCache.containsKey(bookId)) {
      _updateAccessStats(bookId);
      return _epubCache[bookId];
    }
    return null;
  }

  /// Get cached cover image from memory
  static Uint8List? getCachedCoverImage(String bookId) {
    if (_coverCache.containsKey(bookId)) {
      _updateAccessStats(bookId);
      return _coverCache[bookId];
    }
    return null;
  }

  /// Check if book is cached in memory
  static bool isBookCached(String bookId) {
    return _epubCache.containsKey(bookId);
  }

  /// Remove book from cache
  static Future<bool> removeCachedBook(String bookId) async {
    try {
      if (!_epubCache.containsKey(bookId)) {
        return false;
      }

      final sizeBytes = _epubCache[bookId]?.length ?? 0;
      await _removeFromCache(bookId, updateStorage: true);

      print('✅ Removed cached book (${ _formatBytes(sizeBytes) } freed)');
      return true;

    } catch (e) {
      print('❌ Error removing cached book: $e');
      return false;
    }
  }

  /// Get all cached books metadata
  static List<OfflineBook> getCachedBooks() {
    try {
      final allBooks = StorageService.getAllOfflineBooks();
      // Only return books that are actually in memory cache
      return allBooks.where((book) => _epubCache.containsKey(book.bookId)).toList();
    } catch (e) {
      print('❌ Error getting cached books: $e');
      return [];
    }
  }

  /// Get detailed cache information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final totalMemoryUsage = _calculateTotalMemoryUsage();
      final epubSizes = <String, int>{};
      final coverSizes = <String, int>{};

      _epubCache.forEach((key, value) {
        epubSizes[key] = value.length;
      });

      _coverCache.forEach((key, value) {
        coverSizes[key] = value.length;
      });

      return {
        'totalBooks': _epubCache.length,
        'totalSize': totalMemoryUsage,
        'formattedSize': _formatBytes(totalMemoryUsage),
        'epubCacheSize': _epubCache.length,
        'coverCacheSize': _coverCache.length,
        'maxMemoryLimit': _formatBytes(_maxMemoryUsage),
        'memoryUsagePercent': ((totalMemoryUsage / _maxMemoryUsage) * 100).toStringAsFixed(1),
        'bookDetails': epubSizes,
        'averageAccessCount': _accessCounts.values.isEmpty
            ? 0
            : (_accessCounts.values.reduce((a, b) => a + b) / _accessCounts.values.length).toStringAsFixed(1),
      };
    } catch (e) {
      print('❌ Error getting cache info: $e');
      return {
        'totalBooks': 0,
        'totalSize': 0,
        'formattedSize': '0 B',
        'epubCacheSize': 0,
        'coverCacheSize': 0,
      };
    }
  }

  /// Clear all cached content with options
  static Future<bool> clearAllCache({bool keepPopular = false}) async {
    try {
      if (!keepPopular) {
        // Clear everything
        _epubCache.clear();
        _coverCache.clear();
        _cacheTimestamps.clear();
        _accessCounts.clear();

        final cachedBooks = StorageService.getAllOfflineBooks();
        for (final book in cachedBooks) {
          await StorageService.removeOfflineBook(book.bookId);
        }
      } else {
        // Keep books with high access counts
        final popularBooks = _accessCounts.entries
            .where((entry) => entry.value > 3)
            .map((entry) => entry.key)
            .toSet();

        _epubCache.removeWhere((key, value) => !popularBooks.contains(key));
        _coverCache.removeWhere((key, value) => !popularBooks.contains(key));
        _cacheTimestamps.removeWhere((key, value) => !popularBooks.contains(key));
        _accessCounts.removeWhere((key, value) => !popularBooks.contains(key));

        // Update storage
        final allBooks = StorageService.getAllOfflineBooks();
        for (final book in allBooks) {
          if (!popularBooks.contains(book.bookId)) {
            await StorageService.removeOfflineBook(book.bookId);
          }
        }
      }

      print('✅ Successfully cleared cache');
      return true;
    } catch (e) {
      print('❌ Error clearing cache: $e');
      return false;
    }
  }

  /// Preload books for better performance
  static Future<void> preloadBooks(List<Book> books) async {
    print('🚀 Starting preload of ${books.length} books');

    const batchSize = 3; // Process 3 books at a time
    for (int i = 0; i < books.length; i += batchSize) {
      final batch = books.skip(i).take(batchSize).toList();

      final futures = batch.map((book) async {
        if (!isBookCached(book.id)) {
          return cacheBookForOffline(book);
        }
        return true;
      }).toList();

      await Future.wait(futures, eagerError: false);

      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < books.length) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    print('✅ Preload completed');
  }

  /// Get progress stream for a book download
  static Stream<double>? getDownloadProgress(String bookId) {
    return _progressControllers[bookId]?.stream;
  }

  /// Update last access time for a cached book
  static Future<void> updateLastAccess(String bookId) async {
    try {
      if (_epubCache.containsKey(bookId)) {
        _updateAccessStats(bookId);

        final cachedBook = StorageService.getOfflineBook(bookId);
        if (cachedBook != null) {
          cachedBook.lastAccessDate = DateTime.now();
          await StorageService.saveOfflineBook(cachedBook);
        }
      }
    } catch (e) {
      print('❌ Error updating last access: $e');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final totalMemory = _calculateTotalMemoryUsage();
    return {
      'epubsCached': _epubCache.length,
      'coversCached': _coverCache.length,
      'totalMemoryUsage': totalMemory,
      'formattedMemoryUsage': _formatBytes(totalMemory),
      'memoryEfficiency': totalMemory > 0
          ? ((_epubCache.length / (totalMemory / 1024 / 1024)) * 100).toStringAsFixed(1)
          : '0',
      'averageBookSize': _epubCache.isEmpty
          ? 0
          : totalMemory ~/ _epubCache.length,
    };
  }

  /// Calculate total memory usage
  static int _calculateTotalMemoryUsage() {
    int total = 0;
    _epubCache.values.forEach((bytes) => total += bytes.length);
    _coverCache.values.forEach((bytes) => total += bytes.length);
    return total;
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Backward compatibility methods
  static Future<bool> downloadBookForOffline(Book book, {Function(double)? onProgress}) async {
    return await cacheBookForOffline(book, onProgress: onProgress);
  }

  static List<OfflineBook> getOfflineBooks() {
    return getCachedBooks();
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    return await getCacheInfo();
  }

  static Future<bool> removeOfflineBook(String bookId) async {
    return await removeCachedBook(bookId);
  }

  static bool isBookOffline(String bookId) {
    return isBookCached(bookId);
  }

  static OfflineBook? getOfflineBook(String bookId) {
    return StorageService.getOfflineBook(bookId);
  }

  /// Cleanup method to be called when app is closing
  static Future<void> cleanup() async {
    // Close all progress controllers
    for (var controller in _progressControllers.values) {
      await controller.close();
    }
    _progressControllers.clear();

    print('🧹 OfflineService cleanup completed');
  }
}