import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_localization.dart';
import '../../../core/utils/dark_aware_colors.dart';

/// A phone number that opens the dialer when tapped (a call icon makes it
/// obvious). Falls back to plain text when the number is empty.
class TapToCallText extends StatelessWidget {
  const TapToCallText({super.key, required this.phone, this.style});

  final String? phone;
  final TextStyle? style;

  static String _dialable(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _call(BuildContext context) async {
    final number = _dialable(phone ?? '');
    if (number.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('Could not open the phone app.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = (phone ?? '').trim();
    if (text.isEmpty || _dialable(text).length < 7) {
      return Text(text.isEmpty ? '-' : text, style: style);
    }
    final accent = context.acc(const Color(0xFF5F2D82));

    return Semantics(
      button: true,
      label: '${context.tr('Call')} $text',
      child: InkWell(
        onTap: () => _call(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, size: 15, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: (style ?? const TextStyle()).copyWith(
                    color: accent,
                    decoration: TextDecoration.underline,
                    decorationColor: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
