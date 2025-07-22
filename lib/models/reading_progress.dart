import 'package:hive/hive.dart';

part 'reading_progress.g.dart';

@HiveType(typeId: 1)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  int chapterIndex;

  @HiveField(2)
  double progressPercentage;

  @HiveField(3)
  int totalTimeSpentInSeconds;

  @HiveField(4)
  DateTime lastReadAt;

  @HiveField(5)
  List<int> bookmarks;

  ReadingProgress({
    required this.bookId,
    required this.chapterIndex,
    required this.progressPercentage,
    required this.totalTimeSpentInSeconds,
    required this.lastReadAt,
    required this.bookmarks,
  });

  // Add the missing totalReadingTimeMinutes getter/setter for StorageService compatibility
  int get totalReadingTimeMinutes => totalTimeSpentInSeconds ~/ 60;
  set totalReadingTimeMinutes(int minutes) => totalTimeSpentInSeconds = minutes * 60;

  void updateProgress() {
    lastReadAt = DateTime.now();
  }

  String get formattedReadingTime {
    final hours = totalTimeSpentInSeconds ~/ 3600;
    final minutes = (totalTimeSpentInSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get readPercentage => progressPercentage / 100;
}
