class AppConstants {
  // App Information
  static const String appName = 'ReadMile';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your digital library companion';

  // Your actual MongoDB Atlas Configuration
  static const String mongoDbConnectionString =
      'mongodb+srv://mikiemillsyded:Fishpoder123%23@readmile.igbtpmz.mongodb.net/library?retryWrites=true&w=majority&appName=ReadMile&ssl=true&tls=true&tlsAllowInvalidCertificates=false&tlsAllowInvalidHostnames=false';

  static const String databaseName = 'library';
  static const String booksCollection = 'books';
  static const String clusterName = 'readmile';        // Your cluster name
  static const String username = 'mikiemillsyded';     // Your MongoDB username

  // GridFS Collections (for your EPUB files and covers)
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
}
