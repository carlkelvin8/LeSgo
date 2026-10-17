import 'package:flutter/material.dart';
import '../profile/profile_panel.dart';
import '../../../../../../domain/entities/rider_booking.dart';

class RiderBookingStatusButton extends StatelessWidget {
  const RiderBookingStatusButton({
    super.key,
    required this.status,
    required this.isActive,
    this.onTap,
  });
  final BookingStatus status;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = profileDark(context);
    final accent = dark ? const Color(0xFFCFACED) : const Color(0xFF63368B);
    final enabled = isActive && onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: isActive,
      child: Material(
        color: dark
            ? (isActive ? const Color(0xFF30233F) : const Color(0xFF241D30))
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isActive
                ? accent
                : (dark ? const Color(0xFF493B56) : const Color(0xFFE6DFEC)),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isActive
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isActive ? accent : const Color(0xFFB1A6BB),
                ),
                const SizedBox(height: 8),
                Text(
                  status.label.replaceAll('\n', ' '),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isActive ? accent : profileMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
