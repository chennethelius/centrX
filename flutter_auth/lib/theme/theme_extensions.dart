import 'package:flutter/material.dart';
import 'app_theme.dart';

// Extension for easy access to theme values
extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  
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
