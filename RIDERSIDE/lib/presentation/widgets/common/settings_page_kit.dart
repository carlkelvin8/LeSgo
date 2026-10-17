import 'package:flutter/material.dart';

/// Shared look for the merchant/rider settings-style pages
/// (Staff, Notifications, Printer, Security).
class SettingsKit {
  static const brand = Color(0xFF5F2D82);
  static const brandLight = Color(0xFF8A4BD0);
  static const brandTint = Color(0xFFF4EEF8);
  static const pageBg = Color(0xFFFAF8FC);
  static const border = Color(0xFFEAE3F2);
  static const danger = Color(0xFFBE4059);
  static const success = Color(0xFF15816A);
  static const warning = Color(0xFFB85E0C);
  static const ink = Color(0xFF251A38);
  static const muted = Color(0xFF7A6F88);

  static PreferredSizeWidget appBar(
    BuildContext context,
    String title, {
    List<Widget>? actions,
    Color backgroundColor = Colors.white,
  }) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: brand),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.w800,
          color: brand,
        ),
      ),
      actions: actions,
    );
  }

  static BoxDecoration cardDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? border),
      boxShadow: [
        BoxShadow(
          color: brand.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Large in-page title with an optional subtitle, shown under a title-less
/// app bar.
class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: SettingsKit.ink,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                height: 1.4,
                color: SettingsKit.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: SettingsKit.cardDecoration(),
      child: child,
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key, this.color, this.trailing});

  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: color ?? Colors.grey.shade600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon.
class SettingsIconBox extends StatelessWidget {
  const SettingsIconBox({
    super.key,
    required this.icon,
    this.color = SettingsKit.brand,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

class SettingsStatusPill extends StatelessWidget {
  const SettingsStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsEmptyState extends StatelessWidget {
  const SettingsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soft halo with a rounded-square tile, matching the icon boxes
          // used in the settings lists.
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SettingsKit.brand.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: SettingsKit.brandTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: SettingsKit.brand),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: SettingsKit.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              height: 1.5,
              color: SettingsKit.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: SettingsKit.brand,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrollable empty state that still supports pull-to-refresh.
class SettingsScrollableEmpty extends StatelessWidget {
  const SettingsScrollableEmpty({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
