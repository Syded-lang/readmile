import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmile/providers/book_provider.dart';
import 'package:readmile/providers/reading_provider.dart';
import 'package:readmile/providers/offline_provider.dart';
import 'package:readmile/screens/splash/splash_screen.dart';
import 'package:readmile/core/theme.dart';

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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const SplashScreen(),
        },
      ),
    );
  }
}
