import 'package:flutter/material.dart';

bool profileDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color profileText(BuildContext context) =>
    profileDark(context) ? const Color(0xFFF5F0FB) : const Color(0xFF30263C);
Color profileMuted(BuildContext context) =>
    profileDark(context) ? const Color(0xFFB9B1C6) : const Color(0xFF776F80);

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: profileDark(context) ? const Color(0xFF241D30) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: profileDark(context)
            ? const Color(0xFF393044)
            : const Color(0xFFEDE9F2),
      ),
    ),
    child: child,
  );
}
