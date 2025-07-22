class AppConstants {
  // App Information
  static const String appName = 'ReadMile';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your digital library companion';

  // FIXED: MongoDB Atlas Configuration with correct property name
  // In constants.dart - Use SRV format like the documentation examples
  static const String mongoDbConnectionString =
      'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile&tls=true&tlsInsecure=true';

  static const String databaseName = 'library';
  static const String booksCollection = 'books';
  static const String clusterName = 'readmile';
  static const String username = 'mikiemillsyded';

  // GridFS Collections (for EPUB files and covers)
  static const String gridfsFilesCollection = 'fs.files';
  static const String gridfsChunksCollection = 'fs.chunks';


  // Colors
  static const int primaryColorHex = 0xFF730000;
  static const int accentColorHex = 0xFFC5A880;

  // Reading Settings
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const int readingTimerIntervalMinutes = 1;

  // File Storage
  static const String offlineBooksDirectory = 'readmile_offline_books';
  static const String tempDirectory = 'readmile_temp';

  // UI Constants
  static const int homeGridCrossAxisCount = 2;
  static const double bookCardAspectRatio = 0.65;
  static const int maxTitleLines = 2;
  static const int maxAuthorLines = 1;

  // Animation Durations
  static const int splashDurationSeconds = 3;
  static const int pageTransitionMilliseconds = 300;
  static const int snackBarDurationSeconds = 3;

  // Progress Tracking
  static const int progressUpdateIntervalMinutes = 5;
  static const double progressCompleteThreshold = 95.0;

  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again';
  static const String bookLoadErrorMessage = 'Unable to load book. Please try again';
  static const String downloadErrorMessage = 'Download failed. Please try again';
  static const String storageErrorMessage = 'Storage error. Please free up space and try again';

  // Network Configuration
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 5;

  // Reading Experience
  static const List<String> availableFonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Source Sans Pro',
    'Noto Sans'
  ];

  static const List<String> availableThemes = ['light', 'sepia', 'dark'];

  // Cache Settings
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int cacheExpirationDays = 30;

  // Download Settings
  static const int maxConcurrentDownloads = 3;
  static const int downloadTimeoutSeconds = 300; // 5 minutes

  // Search Configuration
  static const int maxSearchResults = 50;
  static const int searchDelayMilliseconds = 500;

  // Backup and Sync
  static const int backupIntervalHours = 24;
  static const bool autoBackupEnabled = true;

  // Feature Flags
  static const bool offlineReadingEnabled = true;
  static const bool analyticsEnabled = true;
  static const bool darkModeEnabled = true;
  static const bool bookmarksEnabled = true;

  // API Endpoints (if needed for future expansion)
  static const String baseApiUrl = 'https://api.readmile.com';
  static const String booksEndpoint = '/books';
  static const String authEndpoint = '/auth';

  // Hive Box Names
  static const String offlineBooksBoxName = 'offline_books';
  static const String readingProgressBoxName = 'reading_progress';
  static const String settingsBoxName = 'settings';
  static const String statsBoxName = 'reading_stats';
}
