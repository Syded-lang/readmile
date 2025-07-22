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

  // Initialize all reading data
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;

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
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
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

  // Check if book is available offline
  bool isBookOffline(String bookId) {
    try {
      return _offlineBooks.any((book) => book.bookId == bookId && book.isAvailable);
    } catch (e) {
      return false;
    }
  }

  // Get reading progress for a specific book
  ReadingProgress? getBookProgress(String bookId) {
    try {
      return _readingProgress.firstWhere((progress) => progress.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  // Download book for offline reading
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

  // Remove offline book
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

  // Update reading progress
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

  // Get recently read books
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

  // Get currently reading books (in progress)
  List<ReadingProgress> getCurrentlyReadingBooks() {
    try {
      return _readingProgress
          .where((progress) => progress.progressPercentage > 0 && progress.progressPercentage < 95)
          .toList()
        ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
    } catch (e) {
      print('❌ Error getting currently reading books: $e');
      return [];
    }
  }

  // Get completed books
  List<ReadingProgress> getCompletedBooks() {
    try {
      return _readingProgress
          .where((progress) => progress.isCompleted)
          .toList()
        ..sort((a, b) => (b.completedDate ?? DateTime(0)).compareTo(a.completedDate ?? DateTime(0)));
    } catch (e) {
      print('❌ Error getting completed books: $e');
      return [];
    }
  }

  // Get progress percentage for a book
  double getProgressPercentage(String bookId) {
    final progress = getBookProgress(bookId);
    return progress?.progressPercentage ?? 0.0;
  }

  // Get total reading time in minutes
  int getTotalReadingTime() {
    return _readingStats['totalReadingTimeMinutes'] ?? 0;
  }

  // Get total books started count
  int getBooksStartedCount() {
    return _readingProgress.length;
  }

  // Get completed books count
  int getCompletedBooksCount() {
    return _readingProgress.where((p) => p.isCompleted).length;
  }

  // Get average reading progress across all books
  double getAverageProgress() {
    if (_readingProgress.isEmpty) return 0.0;

    final totalProgress = _readingProgress
        .fold<double>(0.0, (sum, progress) => sum + progress.progressPercentage);

    return totalProgress / _readingProgress.length;
  }

  // Format total reading time as string
  String getFormattedTotalReadingTime() {
    final minutes = getTotalReadingTime();
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  // Get reading streak (consecutive days)
  int getReadingStreak() {
    if (_readingProgress.isEmpty) return 0;

    final sortedProgress = List<ReadingProgress>.from(_readingProgress)
      ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    int streak = 0;
    DateTime? lastDate;

    for (final progress in sortedProgress) {
      final progressDate = DateTime(
        progress.lastReadDate.year,
        progress.lastReadDate.month,
        progress.lastReadDate.day,
      );

      if (lastDate == null) {
        lastDate = progressDate;
        streak = 1;
      } else {
        final difference = lastDate.difference(progressDate).inDays;
        if (difference == 1) {
          streak++;
          lastDate = progressDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  // Clear all reading data
  Future<void> clearAllData() async {
    try {
      _setLoading(true);

      // Remove all offline books
      for (final offlineBook in _offlineBooks) {
        await OfflineService.removeOfflineBook(offlineBook.bookId);
      }

      // Clear storage
      await StorageService.clearAllData();

      // Reset local data
      _readingProgress.clear();
      _offlineBooks.clear();
      _readingStats.clear();

      notifyListeners();
      print('✅ All reading data cleared');
    } catch (e) {
      _error = 'Error clearing all data: $e';
      print('❌ Error clearing data: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
