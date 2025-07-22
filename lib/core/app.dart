import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/reading_settings_screen.dart';

class ReadMileApp extends StatelessWidget {
  const ReadMileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'ReadMile',
          theme: ThemeData(
            primarySwatch: Colors.red,
            primaryColor: const Color(0xFF730000),
            fontFamily: settings.fontFamily,
          ),
          home: const HomeScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/settings': (context) => const ReadingSettingsScreen(),
            '/app-settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
