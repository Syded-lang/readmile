import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmile/providers/book_provider.dart';
import 'package:readmile/providers/reading_provider.dart';
import 'package:readmile/providers/offline_provider.dart';
import 'package:readmile/screens/home_screen.dart';
import 'package:readmile/core/theme.dart';
import 'package:readmile/core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _loadingText = 'Initializing ReadMile...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Get providers
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final readingProvider = Provider.of<ReadingProvider>(context, listen: false);
      final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);

      // Step 1: Initialize reading and offline data
      _updateLoadingText('Loading your reading progress...');
      await Future.wait([
        readingProvider.initialize(),
        offlineProvider.initialize(),
      ]);

      // Step 2: Load books from MongoDB
      _updateLoadingText('Connecting to your library...');
      await bookProvider.loadBooks();

      // Step 3: Final setup
      _updateLoadingText('Setting up your library...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to home screen - FIXED: Remove books parameter
      if (mounted) {
        _updateLoadingText('Welcome to ReadMile!');
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(), // REMOVED: books parameter
          ),
        );
      }
    } catch (e) {
      print('❌ App initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    }
  }

  void _updateLoadingText(String text) {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return 'Network connection failed.\nPlease check your internet and try again.';
    } else if (error.contains('MongoDB') || error.contains('database')) {
      return 'Database connection failed.\nPlease try again later.';
    } else {
      return 'Something went wrong.\nPlease restart the app.';
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _loadingText = 'Retrying...';
    });
    await _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _hasError ? _buildErrorView() : _buildLoadingView(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo/Title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 48,
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App tagline
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 60),

          // Loading indicator
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            strokeWidth: 3,
          ),

          const SizedBox(height: 24),

          // Loading text with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _loadingText,
              key: ValueKey(_loadingText),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 100),

          // Version info
          Text(
            'Version ${AppConstants.appVersion}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // App name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // Error message
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Retry button
            ElevatedButton.icon(
              onPressed: _retryInitialization,
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}