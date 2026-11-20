import 'package:flutter/material.dart';

/// Spacing scale. Use these instead of ad-hoc numbers so screens line up.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// The one card look used across the app: soft shadow in light mode, a quiet
/// outline in dark mode (shadows disappear on dark backgrounds).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.margin,
    this.onTap,
    this.radius = AppRadius.lg,
  });

  static BoxDecoration decoration(
    BuildContext context, {
    double radius = AppRadius.lg,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return BoxDecoration(
      color: dark ? scheme.surfaceContainerLow : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark
            ? scheme.outlineVariant.withValues(alpha: 0.6)
            : const Color(0xFFEFEAF4),
      ),
      boxShadow: dark
          ? null
          : [
              BoxShadow(
                color: const Color(0xFF5F2D82).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: decoration(context, radius: radius),
      child: onTap == null
          ? body
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: body,
              ),
            ),
    );
  }
}
