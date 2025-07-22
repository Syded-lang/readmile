import 'package:hive/hive.dart';

part 'reading_progress.g.dart';

@HiveType(typeId: 1)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  String bookTitle; // Added to match .g.dart

  @HiveField(2)
  int currentChapter; // Changed from 'chapterIndex' to match .g.dart

  @HiveField(3)
  int totalChapters; // Added to match .g.dart

  @HiveField(4)
  DateTime lastReadDate; // Changed from 'lastReadAt' to match .g.dart

  @HiveField(5)
  int totalReadingTimeMinutes; // Changed from 'totalTimeSpentInSeconds' to match .g.dart

  @HiveField(6)
  double progressPercentage; // Changed from 'readPercentage' to match .g.dart

  @HiveField(7)
  String lastChapterTitle; // Added to match .g.dart

  @HiveField(8)
  bool isCompleted; // Added to match .g.dart

  @HiveField(9)
  DateTime? completedDate; // Added to match .g.dart

  @HiveField(10)
  List<int> bookmarks;

  ReadingProgress({
    required this.bookId,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.lastReadDate,
    this.totalReadingTimeMinutes = 0,
    required this.progressPercentage,
    required this.lastChapterTitle,
    this.isCompleted = false,
    this.completedDate,
    this.bookmarks = const [],
  });

  // Helper getters for compatibility
  int get chapterIndex => currentChapter;
  DateTime get lastReadAt => lastReadDate;
  int get totalTimeSpentInSeconds => totalReadingTimeMinutes * 60;
  double get readPercentage => progressPercentage;

  // Helper method for updating progress
  void updateProgress() {
    lastReadDate = DateTime.now();
    if (progressPercentage >= 0.99 && !isCompleted) {
      isCompleted = true;
      completedDate = DateTime.now();
    }
  }
}