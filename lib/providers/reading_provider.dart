import 'package:flutter/material.dart';
import 'package:readmile/models/reading_progress.dart';
import 'package:readmile/models/offline_book.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/services/storage_service.dart';
import 'package:readmile/services/offline_service.dart';

class ReadingProvider with ChangeNotifier {
  List<ReadingProgress> _readingProgress = [];
  List<OfflineBook> _offlineBooks = [];
  Map<String, dynamic> _readingStats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ReadingProgress> get readingProgress => _readingProgress;
  List<OfflineBook> get offlineBooks => _offlineBooks;
  Map<String, dynamic> get readingStats => _readingStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // FIXED: Initialize without notifyListeners during build
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    // Don't notify listeners here - will be called after build

    try {
      await Future.wait([
        _loadReadingProgress(),
        _loadOfflineBooks(),
        _loadReadingStats(),
      ]);
      print('✅ ReadingProvider initialized successfully');
    } catch (e) {
      _error = 'Error initializing reading data: $e';
      print('❌ ReadingProvider initialization error: $e');
    } finally {
      _isLoading = false;
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _loadReadingProgress() async {
    try {
      _readingProgress = StorageService.getAllReadingProgress();
      print('📊 Loaded ${_readingProgress.length} reading progress records');
    } catch (e) {
      print('❌ Error loading reading progress: $e');
      _readingProgress = [];
    }
  }

  Future<void> _loadOfflineBooks() async {
    try {
      _offlineBooks = StorageService.getAllOfflineBooks();
      print('📱 Loaded ${_offlineBooks.length} offline books');
    } catch (e) {
      print('❌ Error loading offline books: $e');
      _offlineBooks = [];
    }
  }

  Future<void> _loadReadingStats() async {
    try {
      _readingStats = StorageService.getReadingStats();
      print('📈 Loaded reading statistics');
    } catch (e) {
      print('❌ Error loading reading stats: $e');
      _readingStats = {};
    }
  }

  bool isBookOffline(String bookId) {
    try {
      return _offlineBooks.any((book) => book.bookId == bookId && book.isAvailable);
    } catch (e) {
      return false;
    }
  }

  ReadingProgress? getBookProgress(String bookId) {
    try {
      return _readingProgress.firstWhere((progress) => progress.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> downloadBookOffline(Book book, {Function(double)? onProgress}) async {
    try {
      final success = await OfflineService.downloadBookForOffline(book, onProgress: onProgress);
      if (success) {
        await _loadOfflineBooks();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Error downloading book: $e';
      print('❌ Download error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> removeOfflineBook(String bookId) async {
    try {
      await OfflineService.removeOfflineBook(bookId);
      await _loadOfflineBooks();
      notifyListeners();
    } catch (e) {
      _error = 'Error removing offline book: $e';
      print('❌ Remove offline book error: $e');
      notifyListeners();
    }
  }

  Future<void> updateReadingProgress(ReadingProgress progress) async {
    try {
      await StorageService.saveReadingProgress(progress);
      await _loadReadingProgress();
      await _loadReadingStats();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating reading progress: $e';
      print('❌ Update progress error: $e');
      notifyListeners();
    }
  }

  List<ReadingProgress> getRecentlyReadBooks({int limit = 5}) {
    try {
      final sorted = List<ReadingProgress>.from(_readingProgress)
        ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
      return sorted.take(limit).toList();
    } catch (e) {
      print('❌ Error getting recent books: $e');
      return [];
    }
  }

  double getProgressPercentage(String bookId) {
    final progress = getBookProgress(bookId);
    return progress?.progressPercentage ?? 0.0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }
}
