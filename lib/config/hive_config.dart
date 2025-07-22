import 'package:hive_flutter/hive_flutter.dart';
import 'package:readmile/models/reading_progress.dart';
import 'package:readmile/models/offline_book.dart';

class HiveConfig {
  static const String progressBoxName = 'reading_progress';
  static const String offlineBooksBoxName = 'offline_books';
  static const String statsBoxName = 'reading_stats';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReadingProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OfflineBookAdapter());
    }

    // Open boxes
    await Hive.openBox<ReadingProgress>(progressBoxName);
    await Hive.openBox<OfflineBook>(offlineBooksBoxName);
    await Hive.openBox(statsBoxName);

    print('✅ Hive initialized successfully');
  }

  static Future<void> clearAllData() async {
    await Hive.box<ReadingProgress>(progressBoxName).clear();
    await Hive.box<OfflineBook>(offlineBooksBoxName).clear();
    await Hive.box(statsBoxName).clear();
    print('🗑️ All Hive data cleared');
  }
}
