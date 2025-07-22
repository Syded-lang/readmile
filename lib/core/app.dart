import 'package:flutter/material.dart';
import 'theme.dart';
import '../screens/home_screen.dart';
import '../screens/offline/offline_books_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/settings/reading_settings_screen.dart';

class ReadMileApp extends StatelessWidget {
  const ReadMileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadMile',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/offline': (context) => OfflineBooksScreen(),
        '/settings': (context) => const ReadingSettingsScreen(),
      },
    );
  }
}