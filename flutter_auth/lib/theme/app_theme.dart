import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color primaryBlue = Color(0xFF6366F1);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color lightBlue = Color.fromARGB(255, 126, 203, 255);
  static const Color accentGold = Color(0xFFFFD700);
  
  // Surface Colors (for glassmorphism)
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceBlack = Colors.black;
  
  // Status Colors
  static const Color successGreen = Colors.green;
  static const Color warningOrange = Colors.orange;
  static const Color errorRed = Colors.red;
  static const Color infoBlue = Colors.blue;
  static const Color purpleAccent = Colors.purple;

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBlue, primaryBlue],
  );

  static LinearGradient glassmorphismGradient({double opacity1 = 0.25, double opacity2 = 0.1}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaceWhite.withValues(alpha: opacity1),
        surfaceWhite.withValues(alpha: opacity2),
      ],
    );
  }

  // Glass effect colors with different opacities
  static Color glassWhite(double opacity) => surfaceWhite.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => surfaceBlack.withValues(alpha: opacity);

  // Typography Scale (using default fonts for now)
  static const TextTheme textTheme = TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: surfaceWhite,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: surfaceWhite,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: surfaceWhite,
    ),
    
    // Heading styles
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: surfaceWhite,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: surfaceWhite,
    ),
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: surfaceWhite,
    ),
    
    // Body styles
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: surfaceWhite,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: surfaceWhite,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xB3FFFFFF), // surfaceWhite with 70% opacity
    ),
    
    // Label styles
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: surfaceWhite,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xB3FFFFFF), // surfaceWhite with 70% opacity
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: Color(0xB3FFFFFF), // surfaceWhite with 70% opacity
    ),
  );

  // Spacing Scale
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingHuge = 32.0;

  // Border Radius Scale
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusHuge = 28.0;

  // Elevation/Shadow Scale
  static List<BoxShadow> getShadow({
    required String level,
    Color color = surfaceBlack,
    double opacity = 0.1,
  }) {
    switch (level) {
      case 'small':
        return [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      case 'medium':
        return [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ];
      case 'large':
        return [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ];
      default:
        return [];
    }
  }

  // Main Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: primaryCyan,
      tertiary: accentGold,
      surface: surfaceWhite,
      error: errorRed,
    ),
    textTheme: textTheme,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: surfaceWhite,
      ),
      iconTheme: IconThemeData(color: surfaceWhite),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXXL),
      ),
      color: Colors.transparent,
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingXL,
          vertical: spacingM,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: surfaceWhite,
      size: 24,
    ),
  );

  // Dark theme for future use
  static ThemeData get darkTheme => lightTheme.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
    ),
  );
}

// Extension for easy access to theme values
extension AppThemeExtension on ThemeData {
  // Quick access to custom colors
  Color get primaryBlue => AppTheme.primaryBlue;
  Color get primaryCyan => AppTheme.primaryCyan;
  Color get lightBlue => AppTheme.lightBlue;
  Color get accentGold => AppTheme.accentGold;
  
  // Quick access to glassmorphism helpers
  Color glassWhite(double opacity) => AppTheme.glassWhite(opacity);
  Color glassBlack(double opacity) => AppTheme.glassBlack(opacity);
  LinearGradient get backgroundGradient => AppTheme.backgroundGradient;
  LinearGradient glassmorphismGradient({double opacity1 = 0.25, double opacity2 = 0.1}) =>
      AppTheme.glassmorphismGradient(opacity1: opacity1, opacity2: opacity2);
  
  // Quick access to spacing
  double get spacingXS => AppTheme.spacingXS;
  double get spacingS => AppTheme.spacingS;
  double get spacingM => AppTheme.spacingM;
  double get spacingL => AppTheme.spacingL;
  double get spacingXL => AppTheme.spacingXL;
  double get spacingXXL => AppTheme.spacingXXL;
  double get spacingHuge => AppTheme.spacingHuge;
  
  // Quick access to radius
  double get radiusXS => AppTheme.radiusXS;
  double get radiusS => AppTheme.radiusS;
  double get radiusM => AppTheme.radiusM;
  double get radiusL => AppTheme.radiusL;
  double get radiusXL => AppTheme.radiusXL;
  double get radiusXXL => AppTheme.radiusXXL;
  double get radiusHuge => AppTheme.radiusHuge;
  
  // Quick access to shadows
  List<BoxShadow> getShadow({required String level, Color? color, double? opacity}) =>
      AppTheme.getShadow(level: level, color: color ?? Colors.black, opacity: opacity ?? 0.1);
}
