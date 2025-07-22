import 'package:flutter/material.dart';
import 'package:readmile/models/offline_book.dart';
import 'package:readmile/services/offline_service.dart';

class OfflineProvider with ChangeNotifier {
  List<OfflineBook> _offlineBooks = [];
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _downloadingBooks = {};
  Map<String, dynamic> _storageInfo = {};
  bool _isLoading = false;

  List<OfflineBook> get offlineBooks => _offlineBooks;
  Map<String, double> get downloadProgress => _downloadProgress;
  Map<String, dynamic> get storageInfo => _storageInfo;
  bool get isLoading => _isLoading;

  bool isBookDownloading(String bookId) => _downloadingBooks[bookId] ?? false;
  double getDownloadProgress(String bookId) => _downloadProgress[bookId] ?? 0.0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadOfflineBooks(),
      loadStorageInfo(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOfflineBooks() async {
    _offlineBooks = OfflineService.getOfflineBooks();
    print('📱 Loaded ${_offlineBooks.length} offline books');
  }

  Future<void> loadStorageInfo() async {
    _storageInfo = await OfflineService.getStorageInfo();
    print('💾 Storage info: $_storageInfo');
  }

  Future<bool> downloadBook(dynamic book) async {
    final bookId = book.id;

    _downloadingBooks[bookId] = true;
    _downloadProgress[bookId] = 0.0;
    notifyListeners();

    try {
      final success = await OfflineService.downloadBookForOffline(
        book,
        onProgress: (progress) {
          _downloadProgress[bookId] = progress;
          notifyListeners();
        },
      );

      if (success) {
        await loadOfflineBooks();
        await loadStorageInfo();
      }

      return success;
    } catch (e) {
      print('Error downloading book: $e');
      return false;
    } finally {
      _downloadingBooks[bookId] = false;
      _downloadProgress.remove(bookId);
      notifyListeners();
    }
  }

  Future<void> removeBook(String bookId) async {
    try {
      await OfflineService.removeOfflineBook(bookId);
      await loadOfflineBooks();
      await loadStorageInfo();
    } catch (e) {
      print('Error removing offline book: $e');
    }
  }

  Future<bool> isBookAvailable(String bookId) async {
    return await OfflineService.isBookAvailableOffline(bookId);
  }

  Future<void> cleanupStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      await OfflineService.cleanupOrphanedFiles();
      await loadOfflineBooks();
      await loadStorageInfo();
    } catch (e) {
      print('Error cleaning up storage: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  OfflineBook? getOfflineBook(String bookId) {
    try {
      return _offlineBooks.firstWhere((book) => book.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  List<OfflineBook> getRecentlyDownloadedBooks({int limit = 10}) {
    final sorted = List<OfflineBook>.from(_offlineBooks)
      ..sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
    return sorted.take(limit).toList();
  }

  int getTotalOfflineBooks() => _offlineBooks.length;

  int getTotalStorageUsed() {
    return _offlineBooks.fold(0, (sum, book) => sum + book.fileSizeBytes);
  }

  String getFormattedStorageUsed() {
    final bytes = getTotalStorageUsed();
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> removeAllOfflineBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final book in _offlineBooks) {
        await OfflineService.removeOfflineBook(book.bookId);
      }
      await loadOfflineBooks();
      await loadStorageInfo();
    } catch (e) {
      print('Error removing all offline books: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
