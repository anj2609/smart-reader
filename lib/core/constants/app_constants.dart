class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Reader';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Your intelligent reading companion for PDFs, eBooks, and documents';

  // Supported file types
  static const List<String> supportedFileTypes = [
    'pdf',
    'txt',
    'epub',
    'html',
    'htm',
    'md',
  ];

  // Reading speed (words per minute) for time estimates
  static const int averageReadingSpeed = 250;

  // Database
  static const String dbName = 'smart_reader.db';
  static const int dbVersion = 1;

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyFontSize = 'font_size';
  static const String keyFontFamily = 'font_family';
  static const String keyLineSpacing = 'line_spacing';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyReadingGoal = 'reading_goal';
  static const String keyLastOpenedDoc = 'last_opened_doc';

  // Default reader settings
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultLineSpacing = 1.5;
  static const String defaultFontFamily = 'Poppins';

  // Animation durations
  static const int splashDuration = 2500;
  static const int pageTransitionDuration = 300;
  static const int animationDuration = 400;
}
