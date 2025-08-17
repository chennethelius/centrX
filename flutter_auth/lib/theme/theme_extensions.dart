import 'package:flutter/material.dart';
import 'app_theme.dart';

// Extension for easy access to theme values
extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  
  // Quick access to neutral colors (60%)
  Color get neutralWhite => AppTheme.neutralWhite;
  Color get neutralLight => AppTheme.neutralLight;
  Color get neutralGray => AppTheme.neutralGray;
  Color get neutralMedium => AppTheme.neutralMedium;
  Color get neutralDark => AppTheme.neutralDark;
  Color get neutralBlack => AppTheme.neutralBlack;
  
  // Quick access to secondary colors (30%)
  Color get secondaryLight => AppTheme.secondaryLight;
  Color get secondaryGray => AppTheme.secondaryGray;
  Color get secondaryDark => AppTheme.secondaryDark;
  
  // Quick access to accent colors (10%)
  Color get accentNavy => AppTheme.accentNavy;
  Color get accentNavyLight => AppTheme.accentNavyLight;
  Color get accentNavyDark => AppTheme.accentNavyDark;
  
  // Quick access to status colors
  Color get successGreen => AppTheme.successGreen;
  Color get warningOrange => AppTheme.warningOrange;
  Color get errorRed => AppTheme.errorRed;
  Color get infoBlue => AppTheme.infoBlue;
  
  // Quick access to surface colors
  Color get surfaceWhite => AppTheme.surfaceWhite;
  Color get surfaceCard => AppTheme.surfaceCard;
  
  // Quick access to gradients
  LinearGradient get backgroundGradient => AppTheme.backgroundGradient;
  LinearGradient get cardGradient => AppTheme.cardGradient;
  LinearGradient get accentGradient => AppTheme.accentGradient;
  
  // Quick access to surface color helpers
  Color get primarySurface => AppTheme.primarySurface;
  Color get secondarySurface => AppTheme.secondarySurface;
  Color get tertiarySurface => AppTheme.tertiarySurface;
  
  Color primarySurfaceWithOpacity(double opacity) => AppTheme.primarySurfaceWithOpacity(opacity);
  Color secondarySurfaceWithOpacity(double opacity) => AppTheme.secondarySurfaceWithOpacity(opacity);
  Color tertiarySurfaceWithOpacity(double opacity) => AppTheme.tertiarySurfaceWithOpacity(opacity);
  
  Color glassWhite(double opacity) => AppTheme.glassWhite(opacity);
  Color glassBlack(double opacity) => AppTheme.glassBlack(opacity);
  
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
