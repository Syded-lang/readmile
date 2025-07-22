import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/reading_progress.dart';

class ReadingProvider with ChangeNotifier {
  final Box<ReadingProgress> _progressBox;

  ReadingProvider(this._progressBox);

  List<ReadingProgress> get readingProgress => _progressBox.values.toList();

  // Initialize method
  Future<void> initialize() async {
    // Initialization logic if needed
    notifyListeners();
  }

  ReadingProgress? getProgressForBook(String bookId) {
    try {
      return _progressBox.values.firstWhere((progress) => progress.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  // Alternative method name for compatibility
  ReadingProgress? getBookProgress(String bookId) {
    return getProgressForBook(bookId);
  }

  Future<void> updateReadingProgress(String bookId, int chapterIndex, double readPercentage) async {
    try {
      final existingProgress = getProgressForBook(bookId);

      if (existingProgress != null) {
        existingProgress.currentChapter = chapterIndex;
        existingProgress.progressPercentage = readPercentage;
        existingProgress.lastReadDate = DateTime.now();
        existingProgress.updateProgress();
        await existingProgress.save();
      } else {
        final newProgress = ReadingProgress(
          bookId: bookId,
          bookTitle: '', // Will be updated when book info is available
          currentChapter: chapterIndex,
          totalChapters: 100, // Default, will be updated
          lastReadDate: DateTime.now(),
          progressPercentage: readPercentage,
          lastChapterTitle: 'Chapter ${chapterIndex + 1}',
        );
        await _progressBox.add(newProgress);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reading progress: $e');
      }
    }
  }

  Future<void> updateReadingTime(String bookId, int additionalSeconds) async {
    try {
      final existingProgress = getProgressForBook(bookId);

      if (existingProgress != null) {
        existingProgress.totalReadingTimeMinutes += (additionalSeconds / 60).round();
        existingProgress.lastReadDate = DateTime.now();
        existingProgress.updateProgress();
        await existingProgress.save();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reading time: $e');
      }
    }
  }

  Future<void> toggleBookmark(String bookId, int chapterIndex) async {
    try {
      final existingProgress = getProgressForBook(bookId);

      if (existingProgress != null) {
        final bookmarks = List<int>.from(existingProgress.bookmarks);
        if (bookmarks.contains(chapterIndex)) {
          bookmarks.remove(chapterIndex);
        } else {
          bookmarks.add(chapterIndex);
        }
        existingProgress.bookmarks = bookmarks;
        await existingProgress.save();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling bookmark: $e');
      }
    }
  }

  bool isBookmarked(String bookId, int chapterIndex) {
    final progress = getProgressForBook(bookId);
    return progress?.bookmarks.contains(chapterIndex) ?? false;
  }

  Future<void> removeProgress(String bookId) async {
    try {
      final progress = getProgressForBook(bookId);
      if (progress != null) {
        await progress.delete();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing progress: $e');
      }
    }
  }
}