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

  // Performance optimization: Define colors as static constants
  static const Color _primaryColor = Color(0xFF730000);
  static const Color _secondaryColor = Color(0xFFC5A880);
  static const Color _whiteTransparent = Color(0x1AFFFFFF);
  static const Color _whiteTransparent2 = Color(0x33FFFFFF);

  // Performance optimization: Pre-define text styles
  static const TextStyle _titleStyle = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  static const TextStyle _subtitleStyle = TextStyle(
    fontSize: 16,
    color: Color(0xCCFFFFFF), // 80% white opacity
    letterSpacing: 1,
  );

  static const TextStyle _loadingStyle = TextStyle(
    fontSize: 16,
    color: Color(0xE6FFFFFF), // 90% white opacity
  );

  static const TextStyle _errorStyle = TextStyle(
    fontSize: 14,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle _versionStyle = TextStyle(
    fontSize: 12,
    color: Color(0x99FFFFFF), // 60% white opacity
  );

  static const TextStyle _buttonStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  // Performance optimization: Pre-define decorations
  static final BoxDecoration _logoContainerDecoration = BoxDecoration(
    color: _whiteTransparent,
    borderRadius: BorderRadius.circular(100),
  );

  static final BoxDecoration _errorContainerDecoration = BoxDecoration(
    color: _whiteTransparent,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _whiteTransparent2),
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // FIXED: Delay initialization to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
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
      // Get providers safely
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final readingProvider = Provider.of<ReadingProvider>(context, listen: false);
      final offlineProvider = Provider.of<OfflineProvider>(context, listen: false);

      // Step 1: Initialize reading and offline data first
      _updateLoadingText('Loading your reading progress...');
      await Future.wait([
        readingProvider.initialize(),
        offlineProvider.initialize(),
      ]);

      // Step 2: Load books from MongoDB with network error handling
      _updateLoadingText('Connecting to your library...');
      try {
        await bookProvider.loadBooks();
      } catch (e) {
        print('⚠️ Network error, continuing with offline data: $e');
        // Continue with offline data if network fails
      }

      // Step 3: Final setup
      _updateLoadingText('Setting up your library...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to home screen
      if (mounted) {
        _updateLoadingText('Welcome to ReadMile!');
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
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
    if (error.contains('network') || error.contains('connection') || error.contains('SocketException')) {
      return 'Network connection failed.\nContinuing with offline mode.\n\nTap to retry or continue offline.';
    } else if (error.contains('MongoDB') || error.contains('database')) {
      return 'Database connection failed.\nUsing offline data.\n\nTap to retry or continue offline.';
    } else {
      return 'An error occurred during initialization.\n\nTap to retry or continue.';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and branding
              const _LogoSection(),
              const SizedBox(height: 80),

              // Loading or Error Section
              if (!_hasError)
                _LoadingSection(loadingText: _loadingText)
              else
                _ErrorSection(
                  errorMessage: _errorMessage,
                  onRetry: () {
                    setState(() {
                      _hasError = false;
                      _loadingText = 'Retrying...';
                    });
                    _initializeApp();
                  },
                  onContinue: () {
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    }
                  },
                ),

              const SizedBox(height: 40),

              // Version info
              const Text(
                'Version 1.0.0',
                style: _versionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Performance optimization: Extract logo section as separate widget
class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: context.findAncestorStateOfType<_SplashScreenState>()!._fadeAnimation,
      child: ScaleTransition(
        scale: context.findAncestorStateOfType<_SplashScreenState>()!._scaleAnimation,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: _SplashScreenState._logoContainerDecoration,
              child: const Icon(
                Icons.menu_book,
                size: 80,
                color: _SplashScreenState._secondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ReadMile',
              style: _SplashScreenState._titleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Digital Library',
              style: _SplashScreenState._subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

// Performance optimization: Extract loading section
class _LoadingSection extends StatelessWidget {
  final String loadingText;

  const _LoadingSection({required this.loadingText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_SplashScreenState._secondaryColor),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loadingText,
          style: _SplashScreenState._loadingStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Performance optimization: Extract error section
class _ErrorSection extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _ErrorSection({
    required this.errorMessage,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: _SplashScreenState._errorContainerDecoration,
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _SplashScreenState._secondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: _SplashScreenState._errorStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _SplashScreenState._secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: _SplashScreenState._buttonStyle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _SplashScreenState._whiteTransparent2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue Offline',
                    style: _SplashScreenState._buttonStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}