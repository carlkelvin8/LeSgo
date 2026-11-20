import 'package:flutter/material.dart';

/// Semantic dark colours for screens that retain their original light palette.
/// Photos, gradients, status colours, and white labels on brand fills stay intact.
class AppColors {
  AppColors._();

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context, Color light) {
    if (!_dark(context)) return light;
    final scheme = Theme.of(context).colorScheme;
    return (light.computeLuminance() > 0.95
            ? scheme.surface
            : scheme.surfaceContainerLow)
        .withValues(alpha: light.a);
  }

  static Color foreground(BuildContext context, Color light) {
    if (!_dark(context)) return light;
    final scheme = Theme.of(context).colorScheme;
    return (light.computeLuminance() < 0.12
            ? scheme.onSurface
            : scheme.onSurfaceVariant)
        .withValues(alpha: light.a);
  }

  static Color border(BuildContext context, Color light) => _dark(context)
      ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: light.a)
      : light;

  static Color accent(BuildContext context, Color light) => _dark(context)
      ? Theme.of(context).colorScheme.primary.withValues(alpha: light.a)
      : light;

  /// Foreground for a solid fill returned by [accent].
  static Color onAccent(BuildContext context) =>
      _dark(context) ? Theme.of(context).colorScheme.onPrimary : Colors.white;

  /// Fill for primary buttons: brand purple in light mode, the lighter lilac in
  /// dark mode. Pair with [onButton] so every primary action looks the same.
  static Color buttonFill(BuildContext context) => _dark(context)
      ? Theme.of(context).colorScheme.primary
      : const Color(0xFF5F2D82);

  /// Label/icon colour on a [buttonFill].
  static Color onButton(BuildContext context) =>
      _dark(context) ? Theme.of(context).colorScheme.onPrimary : Colors.white;
}
