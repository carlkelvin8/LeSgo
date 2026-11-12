import 'package:flutter/material.dart';

/// Theme-aware colour helpers.
///
/// Each helper takes the colour the screen already used in light mode and
/// returns it unchanged there, so light mode never changes. In dark mode it
/// returns a colour that stays readable on the dark surfaces.
extension DarkAwareColors on BuildContext {
  bool get isDarkUI => Theme.of(this).brightness == Brightness.dark;

  static const Color darkBg = Color(0xFF110E1A);
  static const Color darkSurface = Color(0xFF1E1730);
  static const Color darkSurfaceAlt = Color(0xFF2A2140);
  static const Color darkBorder = Color(0xFF2E2540);
  static const Color darkMuted = Color(0xFFA99BC4);
  static const Color darkAccent = Color(0xFFC9A5F0);

  /// Page background (Scaffold).
  Color bg(Color light) => isDarkUI ? darkBg : light;

  /// Card / sheet / dialog surface. White stays a neutral dark surface; a
  /// pastel tint (light green, light yellow, lilac) becomes a dark tint of the
  /// same hue so tinted banners keep their meaning.
  Color surf(Color light) {
    if (!isDarkUI) return light;
    final hsv = HSVColor.fromColor(light);
    if (hsv.saturation < 0.08) {
      // white / near-white / light grey
      return light.computeLuminance() > 0.93 ? darkSurface : darkSurfaceAlt;
    }
    return Color.alphaBlend(light.withValues(alpha: 0.16), darkSurface);
  }

  /// Dark text / icons that must flip to light text.
  Color txt(Color light) => isDarkUI ? Colors.white : light;

  /// Grey secondary text / icons.
  Color sub(Color light) => isDarkUI ? darkMuted : light;

  /// Brand-purple text / icons, which are too dark on a dark surface.
  Color acc(Color light) => isDarkUI ? darkAccent : light;

  /// Borders and dividers.
  Color brd(Color light) => isDarkUI ? darkBorder : light;
}
