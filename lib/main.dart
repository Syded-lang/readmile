import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmile/providers/book_provider.dart';
import 'package:readmile/providers/reading_provider.dart';
import 'package:readmile/providers/offline_provider.dart';
import 'package:readmile/screens/splash/splash_screen.dart';
import 'package:readmile/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.initialize();

  runApp(const ReadMileApp());
}

class ReadMileApp extends StatelessWidget {
  const ReadMileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
      ],
      child: MaterialApp(
        title: 'ReadMile',
        theme: ThemeData(
          primaryColor: const Color(0xFF730000),
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFC5A880)),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
