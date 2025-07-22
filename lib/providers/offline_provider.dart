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

  // FIXED: Initialize without setState during build
  Future<void> initialize() async {
    _isLoading = true;
    // Don't notify listeners here to avoid setState during build

    try {
      await Future.wait([
        loadOfflineBooks(),
        loadStorageInfo(),
      ]);
      print('✅ OfflineProvider initialized successfully');
    } catch (e) {
      print('❌ OfflineProvider initialization error: $e');
    } finally {
      _isLoading = false;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> loadOfflineBooks() async {
    try {
      _offlineBooks = OfflineService.getOfflineBooks();
      print('📱 Loaded ${_offlineBooks.length} offline books');
    } catch (e) {
      print('❌ Error loading offline books: $e');
      _offlineBooks = [];
    }
  }

  Future<void> loadStorageInfo() async {
    try {
      _storageInfo = await OfflineService.getStorageInfo();
      print('💾 Storage info: $_storageInfo');
    } catch (e) {
      print('❌ Error loading storage info: $e');
      _storageInfo = {};
    }
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
      notifyListeners();
    } catch (e) {
      print('Error removing offline book: $e');
    }
  }

  bool isBookOffline(String bookId) {
    return _offlineBooks.any((book) => book.bookId == bookId && book.isAvailable);
  }

  OfflineBook? getOfflineBook(String bookId) {
    try {
      return _offlineBooks.firstWhere((book) => book.bookId == bookId);
    } catch (e) {
      return null;
    }
  }
}