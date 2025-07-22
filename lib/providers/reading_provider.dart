import 'package:flutter/material.dart';
import 'package:readmile/models/reading_progress.dart';
import 'package:readmile/services/storage_service.dart';
import 'dart:async';

class ReadingProvider with ChangeNotifier {
  List<ReadingProgress> _readingProgress = [];
  bool _isLoading = false;
  String? _error;

  // Batch update optimization
  Timer? _batchUpdateTimer;
  final Set<String> _pendingUpdates = {};

  // Performance tracking
  final Map<String, DateTime> _lastProgressUpdate = {};
  static const Duration _minUpdateInterval = Duration(seconds: 2);

  // Getters
  List<ReadingProgress> get readingProgress => List.unmodifiable(_readingProgress);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize with optimized loading
  Future<void> initialize() async {
    if (_isLoading) return; // Prevent multiple initializations

    _isLoading = true;
    _error = null;

    try {
      final stopwatch = Stopwatch()..start();
      _readingProgress = StorageService.getAllReadingProgress();
      stopwatch.stop();

      print('📊 ReadingProvider initialized: ${_readingProgress.length} records in ${stopwatch.elapsedMilliseconds}ms');

      // Sort by last read date for better performance
      _readingProgress.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    } catch (e) {
      _error = 'Error loading reading progress: $e';
      print('❌ ReadingProvider initialization error: $e');
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Get progress with caching
  ReadingProgress? getProgressForBook(String bookId) {
    // Use firstWhere with orElse for better performance
    try {
      return _readingProgress.firstWhere(
            (p) => p.bookId == bookId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Optimized alias method
  ReadingProgress? getBookProgress(String bookId) {
    return getProgressForBook(bookId);
  }

  /// Batch update reading progress with throttling
  Future<void> updateReadingProgress(String bookId, int chapterIndex, double progressPercentage) async {
    // Throttle rapid updates
    final now = DateTime.now();
    final lastUpdate = _lastProgressUpdate[bookId];

    if (lastUpdate != null && now.difference(lastUpdate) < _minUpdateInterval) {
      // Queue for batch update instead of immediate update
      _pendingUpdates.add(bookId);
      _scheduleBatchUpdate();
      return;
    }

    try {
      final existingIndex = _readingProgress.indexWhere((p) => p.bookId == bookId);

      if (existingIndex != -1) {
        final existing = _readingProgress[existingIndex];

        // Only update if this represents actual progress
        bool shouldUpdate = false;

        if (chapterIndex > existing.chapterIndex) {
          shouldUpdate = true;
        } else if (chapterIndex == existing.chapterIndex &&
            progressPercentage > existing.progressPercentage) {
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          existing.chapterIndex = chapterIndex;
          existing.progressPercentage = progressPercentage;
          existing.lastReadAt = now;

          // Move to front for better cache locality
          if (existingIndex > 0) {
            _readingProgress.removeAt(existingIndex);
            _readingProgress.insert(0, existing);
          }
        }
      } else {
        final newProgress = ReadingProgress(
          bookId: bookId,
          chapterIndex: chapterIndex,
          progressPercentage: progressPercentage,
          totalTimeSpentInSeconds: 0,
          lastReadAt: now,
          bookmarks: [],
        );

        // Insert at beginning for recent access pattern
        _readingProgress.insert(0, newProgress);
      }

      _lastProgressUpdate[bookId] = now;
      await _saveProgressAsync(bookId);

      // Efficient notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

    } catch (e) {
      _error = 'Error updating reading progress: $e';
      print('❌ ReadingProvider update error: $e');
    }
  }

  /// Schedule batch update for performance
  void _scheduleBatchUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(seconds: 5), () {
      _processPendingUpdates();
    });
  }

  /// Process pending updates in batch
  Future<void> _processPendingUpdates() async {
    if (_pendingUpdates.isEmpty) return;

    final bookIds = List<String>.from(_pendingUpdates);
    _pendingUpdates.clear();

    try {
      for (String bookId in bookIds) {
        await _saveProgressAsync(bookId);
      }
      print('✅ Batch updated ${bookIds.length} reading progress records');
    } catch (e) {
      print('❌ Batch update error: $e');
    }
  }

  /// Async save with error handling
  Future<void> _saveProgressAsync(String bookId) async {
    try {
      final progress = getProgressForBook(bookId);
      if (progress != null) {
        await StorageService.saveReadingProgress(progress);
      }
    } catch (e) {
      print('❌ Save progress error for $bookId: $e');
    }
  }

  /// Optimized reading time update
  Future<void> updateReadingTime(String bookId, int additionalSeconds) async {
    if (additionalSeconds <= 0) return;

    try {
      final progress = getProgressForBook(bookId);
      if (progress != null) {
        progress.totalTimeSpentInSeconds += additionalSeconds;

        // Only save if significant time added (reduce I/O)
        if (additionalSeconds >= 30) {
          await _saveProgressAsync(bookId);
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Error updating reading time: $e';
      print('❌ Reading time update error: $e');
    }
  }

  /// Efficient bookmark toggle
  Future<void> toggleBookmark(String bookId, int chapterIndex) async {
    try {
      final progress = getProgressForBook(bookId);
      if (progress != null) {
        if (progress.bookmarks.contains(chapterIndex)) {
          progress.bookmarks.remove(chapterIndex);
        } else {
          progress.bookmarks.add(chapterIndex);
          // Keep bookmarks sorted for better performance
          progress.bookmarks.sort();
        }

        await _saveProgressAsync(bookId);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error toggling bookmark: $e';
      print('❌ Bookmark toggle error: $e');
    }
  }

  /// Fast bookmark check
  bool isBookmarked(String bookId, int chapterIndex) {
    final progress = getProgressForBook(bookId);
    return progress?.bookmarks.contains(chapterIndex) ?? false;
  }

  /// Get reading statistics efficiently
  Map<String, dynamic> getReadingStats() {
    if (_readingProgress.isEmpty) {
      return {
        'totalBooks': 0,
        'totalReadingTime': 0,
        'averageProgress': 0.0,
        'booksCompleted': 0,
      };
    }

    int totalTime = 0;
    double totalProgress = 0;
    int completedBooks = 0;

    for (final progress in _readingProgress) {
      totalTime += progress.totalTimeSpentInSeconds;
      totalProgress += progress.progressPercentage;

      if (progress.progressPercentage >= 95.0) {
        completedBooks++;
      }
    }

    return {
      'totalBooks': _readingProgress.length,
      'totalReadingTime': totalTime,
      'averageProgress': totalProgress / _readingProgress.length,
      'booksCompleted': completedBooks,
    };
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cleanup method
  @override
  void dispose() {
    _batchUpdateTimer?.cancel();
    super.dispose();
  }
}
