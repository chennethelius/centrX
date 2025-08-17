import 'package:flutter/material.dart';

class AppTheme {
  // 60-30-10 Color Palette Design
  
  // Primary Colors (60% - Neutral Base)
  static const Color neutralWhite = Color(0xFFFAFAFA);      // Main background
  static const Color neutralLight = Color(0xFFF5F5F5);      // Secondary backgrounds
  static const Color neutralGray = Color(0xFFE5E5E5);       // Borders, dividers
  static const Color neutralMedium = Color(0xFF9E9E9E);     // Placeholder text
  static const Color neutralDark = Color(0xFF424242);       // Body text
  static const Color neutralBlack = Color(0xFF212121);      // Headings
  
  // Secondary Colors (30% - Supporting Neutrals)
  static const Color secondaryLight = Color(0xFFF8F9FA);    // Card backgrounds
  static const Color secondaryGray = Color(0xFFDEE2E6);     // Input backgrounds
  static const Color secondaryDark = Color(0xFF6C757D);     // Secondary text
  
  // Accent Color (10% - Navy)
  static const Color accentNavy = Color(0xFF1E3A8A);        // Primary actions, buttons
  static const Color accentNavyLight = Color(0xFF3B82F6);   // Hover states
  static const Color accentNavyDark = Color(0xFF1E40AF);    // Active states
  
  // Status Colors (minimal usage)
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  
  // Surface Colors
  static const Color surfaceWhite = neutralWhite;
  static const Color surfaceCard = secondaryLight;
  
  // Gradient Combinations - Minimal and clean
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      neutralWhite,
      neutralLight,
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondaryLight,
      neutralLight,
    ],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentNavy,
      accentNavyLight,
    ],
  );

  // Primary surface colors for cards and containers
  static Color get primarySurface => accentNavy;
  static Color get secondarySurface => secondaryLight;
  static Color get tertiarySurface => neutralGray;
  
  // Surface variations with opacity
  static Color primarySurfaceWithOpacity(double opacity) => accentNavy.withValues(alpha: opacity);
  static Color secondarySurfaceWithOpacity(double opacity) => secondaryLight.withValues(alpha: opacity);
  static Color tertiarySurfaceWithOpacity(double opacity) => neutralGray.withValues(alpha: opacity);

  // Glass effect colors with different opacities
  static Color glassWhite(double opacity) => surfaceWhite.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => neutralDark.withValues(alpha: opacity);

  // Typography Scale (using neutral colors)
  static const TextTheme textTheme = TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: neutralBlack,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: neutralBlack,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: neutralBlack,
    ),
    
    // Heading styles
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: neutralBlack,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: neutralDark,
    ),
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: neutralDark,
    ),
    
    // Body styles
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: neutralDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: neutralDark,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: neutralMedium,
    ),
    
    // Label styles
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: neutralDark,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: neutralMedium,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: neutralMedium,
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
    Color color = neutralDark,
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
      seedColor: accentNavy,
      brightness: Brightness.light,
      primary: accentNavy,
      secondary: secondaryGray,
      tertiary: accentNavyLight,
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
        color: neutralBlack,
      ),
      iconTheme: IconThemeData(color: neutralBlack),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXXL),
      ),
      color: surfaceCard,
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentNavy,
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
      color: neutralDark,
      size: 24,
    ),
  );

  // Dark theme for future use
  static ThemeData get darkTheme => lightTheme.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentNavy,
      brightness: Brightness.dark,
    ),
  );
}
