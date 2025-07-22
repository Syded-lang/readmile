import 'package:mongo_dart/mongo_dart.dart';
import 'package:readmile/core/constants.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';

class GridFSService {
  static const String _connectionString = AppConstants.mongoDbConnectionString;

  // Enhanced memory cache with size limits
  static final Map<String, Uint8List> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, int> _cacheAccessCount = {};
  static int _currentCacheSize = 0;

  // Configuration
  static const Duration _cacheExpiration = Duration(hours: 2);
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB max cache
  static const int _maxCacheItems = 100;
  static const int _connectionPoolSize = 3;

  // Connection pool management
  static final List<Db> _connectionPool = [];
  static final List<bool> _connectionInUse = [];
  static DateTime? _lastCleanup;
  static const Duration _cleanupInterval = Duration(minutes: 10);

  // Batch processing
  static final Map<String, Completer<Uint8List?>> _pendingRequests = {};
  static Timer? _batchTimer;
  static final Set<String> _batchQueue = {};

  /// Initialize connection pool
  static Future<void> _initializePool() async {
    if (_connectionPool.isNotEmpty) return;

    for (int i = 0; i < _connectionPoolSize; i++) {
      try {
        final db = await Db.create(_connectionString);
        await db.open();
        _connectionPool.add(db);
        _connectionInUse.add(false);
      } catch (e) {
        print('⚠️ Failed to create connection $i: $e');
      }
    }
  }

  /// Get available connection from pool
  Future<Db?> _getConnection() async {
    await _initializePool();

    // Find available connection
    for (int i = 0; i < _connectionPool.length; i++) {
      if (!_connectionInUse[i]) {
        _connectionInUse[i] = true;
        return _connectionPool[i];
      }
    }

    // No available connections, create temporary one
    try {
      final db = await Db.create(_connectionString);
      await db.open();
      return db;
    } catch (e) {
      print('❌ Failed to create temporary connection: $e');
      return null;
    }
  }

  /// Release connection back to pool
  void _releaseConnection(Db db) {
    for (int i = 0; i < _connectionPool.length; i++) {
      if (_connectionPool[i] == db) {
        _connectionInUse[i] = false;
        return;
      }
    }
    // If it's a temporary connection, close it
    db.close().catchError((e) => print('⚠️ Error closing temp connection: $e'));
  }

  /// Smart cache management with LRU eviction
  void _manageCacheSize() {
    final now = DateTime.now();

    // Clean expired items first
    final expiredKeys = <String>[];
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredKeys.add(key);
      }
    });

    for (String key in expiredKeys) {
      _currentCacheSize -= _imageCache[key]?.length ?? 0;
      _imageCache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheAccessCount.remove(key);
    }

    // If still over limit, remove least recently used items
    while ((_currentCacheSize > _maxCacheSize || _imageCache.length > _maxCacheItems)
        && _imageCache.isNotEmpty) {

      String oldestKey = _cacheAccessCount.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;

      _currentCacheSize -= _imageCache[oldestKey]?.length ?? 0;
      _imageCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
      _cacheAccessCount.remove(oldestKey);
    }

    // Periodic cleanup
    if (_lastCleanup == null || now.difference(_lastCleanup!) > _cleanupInterval) {
      _lastCleanup = now;
      print('🧹 Cache cleanup: ${_imageCache.length} items, ${(_currentCacheSize / 1024 / 1024).toStringAsFixed(1)}MB');
    }
  }

  /// Batch image loading for better performance
  Future<Uint8List?> getCoverImage(String gridfsId) async {
    if (gridfsId.isEmpty) return null;

    // Check cache first
    if (_imageCache.containsKey(gridfsId)) {
      _cacheAccessCount[gridfsId] = (_cacheAccessCount[gridfsId] ?? 0) + 1;
      print('📱 Cache hit for cover: ObjectId("$gridfsId")');
      return _imageCache[gridfsId];
    }

    // Check if request is already pending
    if (_pendingRequests.containsKey(gridfsId)) {
      return await _pendingRequests[gridfsId]!.future;
    }

    // Create completer for this request
    final completer = Completer<Uint8List?>();
    _pendingRequests[gridfsId] = completer;

    // Add to batch queue
    _batchQueue.add(gridfsId);

    // Start batch timer if not already running
    _batchTimer ??= Timer(Duration(milliseconds: 50), _processBatch);

    return completer.future;
  }

  /// Process batch of image requests
  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      _batchTimer = null;
      return;
    }

    final batchIds = _batchQueue.toList();
    _batchQueue.clear();
    _batchTimer = null;

    final db = await _getConnection();
    if (db == null) {
      // Fail all pending requests
      for (String id in batchIds) {
        _pendingRequests[id]?.complete(null);
        _pendingRequests.remove(id);
      }
      return;
    }

    try {
      await _processBatchWithConnection(db, batchIds);
    } finally {
      _releaseConnection(db);
    }
  }

  /// Process batch with database connection
  Future<void> _processBatchWithConnection(Db db, List<String> batchIds) async {
    final chunksCollection = db.collection('fs.chunks');

    // Convert IDs to ObjectIds
    final objectIds = <ObjectId>[];
    final idMapping = <ObjectId, String>{};

    for (String id in batchIds) {
      try {
        String hexString = id;
        if (id.startsWith('ObjectId("') && id.endsWith('")')) {
          hexString = id.substring(10, id.length - 2);
        }

        final objectId = ObjectId.fromHexString(hexString);
        objectIds.add(objectId);
        idMapping[objectId] = id;
      } catch (e) {
        print('❌ Invalid ObjectId: $id - $e');
        _pendingRequests[id]?.complete(null);
        _pendingRequests.remove(id);
      }
    }

    if (objectIds.isEmpty) return;

    try {
      // Batch query for all chunks
      final cursor = chunksCollection.find(
          where.oneFrom('files_id', objectIds).sortBy('files_id').sortBy('n')
      );

      final allChunks = await cursor.toList();
      final groupedChunks = <ObjectId, List<Map<String, dynamic>>>{};

      // Group chunks by file ID
      for (var chunk in allChunks) {
        final fileId = chunk['files_id'] as ObjectId;
        groupedChunks.putIfAbsent(fileId, () => []).add(chunk);
      }

      // Process each file
      for (var entry in groupedChunks.entries) {
        final objectId = entry.key;
        final chunks = entry.value;
        final gridfsId = idMapping[objectId]!;

        try {
          final result = await _assembleChunks(chunks);
          if (result != null) {
            // Cache the result
            _manageCacheSize();
            _imageCache[gridfsId] = result;
            _cacheTimestamps[gridfsId] = DateTime.now();
            _cacheAccessCount[gridfsId] = 1;
            _currentCacheSize += result.length;

            print('✅ Successfully loaded and cached ${result.length} bytes for cover');
          }

          _pendingRequests[gridfsId]?.complete(result);
        } catch (e) {
          print('❌ Error assembling chunks for $gridfsId: $e');
          _pendingRequests[gridfsId]?.complete(null);
        }

        _pendingRequests.remove(gridfsId);
      }

      // Handle missing files
      for (String id in batchIds) {
        if (_pendingRequests.containsKey(id)) {
          print('⚠️ No chunks found for GridFS ID: $id');
          _pendingRequests[id]?.complete(null);
          _pendingRequests.remove(id);
        }
      }

    } catch (e) {
      print('❌ Batch GridFS loading error: $e');
      // Fail all remaining requests
      for (String id in batchIds) {
        _pendingRequests[id]?.complete(null);
        _pendingRequests.remove(id);
      }
    }
  }

  /// Efficiently assemble chunks using isolate for large files
  Future<Uint8List?> _assembleChunks(List<Map<String, dynamic>> chunks) async {
    if (chunks.isEmpty) return null;

    // Sort chunks by n field
    chunks.sort((a, b) => (a['n'] as int).compareTo(b['n'] as int));

    // Calculate total size
    int totalSize = 0;
    for (var chunk in chunks) {
      final data = chunk['data'];
      if (data is BsonBinary) {
        totalSize += data.byteList.length;
      }
    }

    // For large files, use isolate to avoid blocking UI
    if (totalSize > 1024 * 1024) { // 1MB threshold
      return await _assembleChunksInIsolate(chunks, totalSize);
    }

    // Small files - process on main thread
    final List<int> allBytes = List<int>.filled(totalSize, 0);
    int currentIndex = 0;

    for (var chunk in chunks) {
      final data = chunk['data'];
      if (data is BsonBinary) {
        allBytes.setRange(currentIndex, currentIndex + data.byteList.length, data.byteList);
        currentIndex += data.byteList.length;
      }
    }

    return Uint8List.fromList(allBytes);
  }

  /// Assemble chunks in isolate for large files
  Future<Uint8List?> _assembleChunksInIsolate(List<Map<String, dynamic>> chunks, int totalSize) async {
    try {
      final receivePort = ReceivePort();

      // Prepare data for isolate
      final chunkData = <List<int>>[];
      for (var chunk in chunks) {
        final data = chunk['data'];
        if (data is BsonBinary) {
          chunkData.add(data.byteList);
        }
      }

      await Isolate.spawn(_assembleChunksWorker, {
        'chunks': chunkData,
        'totalSize': totalSize,
        'sendPort': receivePort.sendPort,
      });

      final result = await receivePort.first;
      return result as Uint8List?;
    } catch (e) {
      print('❌ Isolate assembly failed, falling back to main thread: $e');
      // Fallback to main thread
      return await _assembleChunks(chunks);
    }
  }

  /// Worker function for isolate
  static void _assembleChunksWorker(Map<String, dynamic> params) {
    final chunks = params['chunks'] as List<List<int>>;
    final totalSize = params['totalSize'] as int;
    final sendPort = params['sendPort'] as SendPort;

    try {
      final List<int> allBytes = List<int>.filled(totalSize, 0);
      int currentIndex = 0;

      for (var chunkData in chunks) {
        allBytes.setRange(currentIndex, currentIndex + chunkData.length, chunkData);
        currentIndex += chunkData.length;
      }

      sendPort.send(Uint8List.fromList(allBytes));
    } catch (e) {
      sendPort.send(null);
    }
  }

  /// Preload multiple covers for better UX
  Future<void> preloadCovers(List<String> gridfsIds) async {
    final uncachedIds = gridfsIds.where((id) => !_imageCache.containsKey(id)).toList();

    if (uncachedIds.isEmpty) return;

    print('🚀 Preloading ${uncachedIds.length} covers');

    // Process in smaller batches to avoid overwhelming the system
    const batchSize = 10;
    for (int i = 0; i < uncachedIds.length; i += batchSize) {
      final batch = uncachedIds.skip(i).take(batchSize).toList();
      final futures = batch.map((id) => getCoverImage(id)).toList();
      await Future.wait(futures, eagerError: false);

      // Small delay between batches
      if (i + batchSize < uncachedIds.length) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'items': _imageCache.length,
      'sizeBytes': _currentCacheSize,
      'sizeMB': (_currentCacheSize / 1024 / 1024).toStringAsFixed(1),
      'hitRate': _cacheAccessCount.values.fold<int>(0, (sum, count) => sum + count),
    };
  }

  /// Clear cache with options
  void clearCache({bool keepFrequentlyUsed = false}) {
    if (!keepFrequentlyUsed) {
      _imageCache.clear();
      _cacheTimestamps.clear();
      _cacheAccessCount.clear();
      _currentCacheSize = 0;
    } else {
      // Keep items accessed more than 3 times
      final keysToKeep = _cacheAccessCount.entries
          .where((entry) => entry.value > 3)
          .map((entry) => entry.key)
          .toSet();

      _imageCache.removeWhere((key, value) => !keysToKeep.contains(key));
      _cacheTimestamps.removeWhere((key, value) => !keysToKeep.contains(key));
      _cacheAccessCount.removeWhere((key, value) => !keysToKeep.contains(key));

      _currentCacheSize = _imageCache.values.fold<int>(0, (sum, data) => sum + data.length);
    }

    print('🧹 GridFS cache cleared');
  }

  /// Download file - alias for getCoverImage for backward compatibility
  Future<Uint8List?> downloadFile(String gridfsId) async {
    return await getCoverImage(gridfsId);
  }

  /// Download cover - alias for getCoverImage
  Future<Uint8List?> downloadCover(String bookId) async {
    return await getCoverImage(bookId);
  }

  /// Get file metadata efficiently
  Future<Map<String, dynamic>?> getFileInfo(String gridfsId) async {
    try {
      String hexString = gridfsId;
      if (gridfsId.startsWith('ObjectId("') && gridfsId.endsWith('")')) {
        hexString = gridfsId.substring(10, gridfsId.length - 2);
      }

      final db = await _getConnection();
      if (db == null) return null;

      try {
        final objectId = ObjectId.fromHexString(hexString);
        final filesCollection = db.collection('fs.files');
        final fileInfo = await filesCollection.findOne(where.eq('_id', objectId));
        return fileInfo;
      } finally {
        _releaseConnection(db);
      }
    } catch (e) {
      print('❌ Error getting file info: $e');
      return null;
    }
  }

  /// Close all connections and cleanup
  Future<void> close() async {
    _batchTimer?.cancel();

    // Complete any pending requests
    for (var completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _pendingRequests.clear();
    _batchQueue.clear();

    // Close all connections in pool
    for (int i = 0; i < _connectionPool.length; i++) {
      try {
        await _connectionPool[i].close();
      } catch (e) {
        print('⚠️ Error closing connection $i: $e');
      }
    }

    _connectionPool.clear();
    _connectionInUse.clear();
    print('🔒 GridFS service closed');
  }
}