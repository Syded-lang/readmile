import 'package:hive_flutter/hive_flutter.dart';

part 'reading_progress.g.dart';

@HiveType(typeId: 0)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  String bookTitle;

  @HiveField(2)
  int currentChapter;

  @HiveField(3)
  int totalChapters;

  @HiveField(4)
  DateTime lastReadDate;

  @HiveField(5)
  int totalReadingTimeMinutes;

  @HiveField(6)
  double progressPercentage;

  @HiveField(7)
  String lastChapterTitle;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  DateTime? completedDate;

  ReadingProgress({
    required this.bookId,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.lastReadDate,
    this.totalReadingTimeMinutes = 0,
    this.progressPercentage = 0.0,
    this.lastChapterTitle = '',
    this.isCompleted = false,
    this.completedDate,
  });

  void updateProgress() {
    if (totalChapters > 0) {
      progressPercentage = (currentChapter / totalChapters) * 100;

      // Mark as completed if progress is above threshold
      if (progressPercentage >= 95.0 && !isCompleted) {
        isCompleted = true;
        completedDate = DateTime.now();
      }
    }
  }

  String get formattedReadingTime {
    if (totalReadingTimeMinutes < 60) {
      return '${totalReadingTimeMinutes}m';
    } else {
      final hours = totalReadingTimeMinutes ~/ 60;
      final minutes = totalReadingTimeMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  String get progressText => '${currentChapter + 1}/$totalChapters chapters';

  @override
  String toString() {
    return 'ReadingProgress(bookId: $bookId, progress: ${progressPercentage.toStringAsFixed(1)}%, time: $formattedReadingTime)';
  }
}
