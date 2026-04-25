import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600 && screenWidth(context) < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1024;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 64.0;
    if (isTablet(context)) return 48.0;
    return 32.0;
  }

  static double fontSize(BuildContext context, double baseSize) {
    double width = screenWidth(context);
    if (width < 360) return baseSize * 0.85;
    if (width < 400) return baseSize * 0.95;
    if (width > 600) return baseSize * 1.1;
    return baseSize;
  }

  static double spacing(BuildContext context, double baseSpacing) {
    double width = screenWidth(context);
    if (width < 360) return baseSpacing * 0.75;
    if (width < 400) return baseSpacing * 0.9;
    if (width > 600) return baseSpacing * 1.2;
    return baseSpacing;
  }

  static double maxContentWidth(BuildContext context) {
    return isDesktop(context) ? 600 : double.infinity;
  }

  static double imageHeight(BuildContext context, double baseHeight) {
    double width = screenWidth(context);
    if (width < 360) return baseHeight * 0.7;
    if (width > 600) return baseHeight * 1.2;
    return baseHeight;
  }

  static double buttonHeight(BuildContext context) {
    return isMobile(context) ? 48.0 : 56.0;
  }

  // Card-specific responsive utilities
  static double cardImageSize(BuildContext context, double baseSize) {
    double width = screenWidth(context);
    if (width < 360) return baseSize * 0.7;
    if (width < 400) return baseSize * 0.85;
    if (width > 600) return baseSize * 1.15;
    return baseSize;
  }

  static double cardPadding(BuildContext context) {
    double width = screenWidth(context);
    if (width < 360) return 10.0;
    if (width < 400) return 12.0;
    if (width > 600) return 20.0;
    return 16.0;
  }

  static int cardDescriptionMaxLines(BuildContext context) {
    double width = screenWidth(context);
    if (width < 360) return 2;
    if (width < 400) return 3;
    return 4;
  }
}
