import 'package:hive_flutter/hive_flutter.dart';

part 'offline_book.g.dart';

@HiveType(typeId: 1)
class OfflineBook extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String localFilePath;

  @HiveField(4)
  DateTime downloadDate;

  @HiveField(5)
  int fileSizeBytes;

  @HiveField(6)
  List<String> categories;

  @HiveField(7)
  bool isAvailable;

  @HiveField(8)
  String coverPath;

  @HiveField(9)
  DateTime lastAccessDate;

  OfflineBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.localFilePath,
    required this.downloadDate,
    required this.fileSizeBytes,
    required this.categories,
    this.isAvailable = true,
    this.coverPath = '',
    DateTime? lastAccessDate,
  }) : lastAccessDate = lastAccessDate ?? DateTime.now();

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes}B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get downloadDateFormatted {
    final now = DateTime.now();
    final difference = now.difference(downloadDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${downloadDate.day}/${downloadDate.month}/${downloadDate.year}';
    }
  }

  void markAccessed() {
    lastAccessDate = DateTime.now();
    save(); // Save to Hive
  }

  @override
  String toString() {
    return 'OfflineBook(title: $title, size: $fileSizeFormatted, available: $isAvailable)';
  }
}
