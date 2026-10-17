import 'package:flutter/material.dart';
import 'profile_panel.dart';
import '../more/rider_more_components.dart';

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final dark = profileDark(context);
    final accent = destructive
        ? (dark ? const Color(0xFFFF9E9E) : const Color(0xFFBB3945))
        : (dark ? const Color(0xFFD3B1F1) : const Color(0xFF63368B));
    return MoreMenuRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      accent: accent,
      titleColor: destructive ? accent : null,
      onTap: onTap,
    );
  }
}
