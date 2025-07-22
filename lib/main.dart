import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/hive_config.dart';
import 'core/app.dart';
import 'models/offline_book.dart';
import 'models/reading_progress.dart';
import 'providers/book_provider.dart';
import 'providers/offline_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters if you have them
  // Hive.registerAdapter(OfflineBookAdapter());
  // Hive.registerAdapter(ReadingProgressAdapter());

  // Open boxes
  await Hive.openBox<OfflineBook>('offlineBooks');
  await Hive.openBox<ReadingProgress>('readingProgress');

  // Initialize services
  final apiService = ApiService();
  final offlineService = OfflineService();

  // Get Hive boxes
  final offlineBooksBox = Hive.box<OfflineBook>('offlineBooks');
  final readingProgressBox = Hive.box<ReadingProgress>('readingProgress');

  // Initialize settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BookProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineProvider(offlineBooksBox, offlineService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReadingProvider(readingProgressBox),
        ),
        ChangeNotifierProvider.value(
          value: settingsProvider,
        ),
      ],
      child: const ReadMileApp(),
    ),
  );
}