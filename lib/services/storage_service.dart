import 'package:hive_flutter/hive_flutter.dart';
import 'package:readmile/models/reading_progress.dart';
import 'package:readmile/models/offline_book.dart';

class StorageService {
  static const String progressBoxName = 'reading_progress';
  static const String offlineBooksBoxName = 'offline_books';
  static const String statsBoxName = 'reading_stats';

  static Future<void> initialize() async {
    // Don't initialize Hive or register adapters here - HiveConfig already does it
    // Just open the boxes
    await Hive.openBox<ReadingProgress>(progressBoxName);
    await Hive.openBox<OfflineBook>(offlineBooksBoxName);
    await Hive.openBox(statsBoxName);
  }

  static Future<void> saveReadingProgress(ReadingProgress progress) async {
    final box = Hive.box<ReadingProgress>(progressBoxName);
    progress.updateProgress();
    await box.put(progress.bookId, progress);
  }

  static ReadingProgress? getReadingProgress(String bookId) {
    final box = Hive.box<ReadingProgress>(progressBoxName);
    return box.get(bookId);
  }

  static List<ReadingProgress> getAllReadingProgress() {
    final box = Hive.box<ReadingProgress>(progressBoxName);
    return box.values.toList();
  }

  static Future<void> updateReadingTime(String bookId, int additionalMinutes) async {
    final progress = getReadingProgress(bookId);
    if (progress != null) {
      progress.totalReadingTimeMinutes += additionalMinutes;
      await saveReadingProgress(progress);
    }
  }

  static Future<void> saveOfflineBook(OfflineBook offlineBook) async {
    final box = Hive.box<OfflineBook>(offlineBooksBoxName);
    await box.put(offlineBook.bookId, offlineBook);
  }

  static OfflineBook? getOfflineBook(String bookId) {
    final box = Hive.box<OfflineBook>(offlineBooksBoxName);
    return box.get(bookId);
  }

  static List<OfflineBook> getAllOfflineBooks() {
    final box = Hive.box<OfflineBook>(offlineBooksBoxName);
    return box.values.where((book) => book.isAvailable).toList();
  }

  static Future<void> updateTotalReadingTime(int minutes) async {
    final box = Hive.box(statsBoxName);
    final currentTotal = box.get('total_reading_time', defaultValue: 0) as int;
    await box.put('total_reading_time', currentTotal + minutes);
  }

  static Map<String, dynamic> getReadingStats() {
    final box = Hive.box(statsBoxName);
    final totalTime = box.get('total_reading_time', defaultValue: 0) as int;
    return {'totalReadingTimeMinutes': totalTime};
  }

  static Future<void> clearAllData() async {
    final progressBox = Hive.box<ReadingProgress>(progressBoxName);
    final offlineBox = Hive.box<OfflineBook>(offlineBooksBoxName);
    final statsBox = Hive.box(statsBoxName);
    await progressBox.clear();
    await offlineBox.clear();
    await statsBox.clear();
  }

  static bool isBookOffline(String bookId) {
    final offlineBook = getOfflineBook(bookId);
    return offlineBook != null && offlineBook.isAvailable;
  }

  static Future<void> removeOfflineBook(String bookId) async {
    final box = Hive.box<OfflineBook>(offlineBooksBoxName);
    await box.delete(bookId);
  }
}
