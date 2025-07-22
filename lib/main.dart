import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app.dart';
import 'config/hive_config.dart';
import 'providers/book_provider.dart';
import 'providers/offline_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive first (critical fix)
    await HiveConfig.init();
    print('✅ Hive initialized successfully');

    // Initialize storage service
    await StorageService.initialize();
    print('✅ Storage service initialized');

    // Initialize settings provider
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();
    print('✅ Settings provider initialized');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BookProvider()),
          ChangeNotifierProvider(create: (_) => OfflineProvider()),
          ChangeNotifierProvider(create: (_) => ReadingProvider()),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const ReadMileApp(),
      ),
    );

  } catch (e) {
    print('❌ Initialization error: $e');

    // Fallback app with error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('App initialization failed', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Please restart the app', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
