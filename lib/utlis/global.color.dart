import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import '../utils/theme_manager.dart';

class GlobalColor {
  static HexColor mainColor = HexColor('#901018');
  static HexColor textColor = HexColor('#4F4F4F');

  // Theme-aware colors
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? textColor;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.color ??
        textColor.withOpacity(0.7);
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  static List<Color> getGradientColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getGradientColors(isDarkMode);
  }

  static Color getShadowColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getShadowColor(isDarkMode);
  }
}
