import 'package:hive/hive.dart';

part 'offline_book.g.dart';

@HiveType(typeId: 0)
class OfflineBook extends HiveObject {
  @HiveField(0)
  String bookId; // Changed from 'id' to match .g.dart

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String localFilePath;

  @HiveField(4)
  String coverPath; // Changed from 'localCoverPath' to match .g.dart

  @HiveField(5)
  DateTime downloadDate; // Changed from 'downloadedAt' to match .g.dart

  @HiveField(6)
  int fileSizeBytes;

  @HiveField(7)
  List<String> categories;

  @HiveField(8)
  bool isAvailable; // Added to match .g.dart

  @HiveField(9)
  DateTime lastAccessDate; // Added to match .g.dart

  OfflineBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.localFilePath,
    required this.coverPath,
    required this.downloadDate,
    required this.fileSizeBytes,
    required this.categories,
    this.isAvailable = true,
    required this.lastAccessDate,
  });

  // Helper getters for compatibility
  String get id => bookId;
  String get localCoverPath => coverPath;
  DateTime get downloadedAt => downloadDate;

  // Formatted getters
  String get downloadDateFormatted {
    return "${downloadDate.day}/${downloadDate.month}/${downloadDate.year}";
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return "$fileSizeBytes B";
    } else if (fileSizeBytes < 1024 * 1024) {
      return "${(fileSizeBytes / 1024).toStringAsFixed(1)} KB";
    } else {
      return "${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
  }
}