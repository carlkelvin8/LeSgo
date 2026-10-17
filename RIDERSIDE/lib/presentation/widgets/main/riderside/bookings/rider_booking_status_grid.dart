import 'package:flutter/material.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../profile/profile_panel.dart';

/// A single chronological timeline for the booking workflow.
class RiderBookingStatusGrid extends StatelessWidget {
  final RiderBooking booking;
  final BookingStatus currentStatus;
  final Function(BookingStatus)? onStatusTap;

  const RiderBookingStatusGrid({
    super.key,
    required this.booking,
    required this.currentStatus,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final cancelled = currentStatus == BookingStatus.cancelled;
    final statuses = [
      ...booking.category.statuses,
      if (cancelled) BookingStatus.cancelled,
    ];
    final currentIndex = statuses.indexOf(currentStatus.workflowStep);
    final dark = profileDark(context);
    final accent = dark ? const Color(0xFFCFACED) : const Color(0xFF5F2D82);
    final line = dark ? const Color(0xFF493B56) : const Color(0xFFE6DFEC);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 8,
                  color: !cancelled && i <= currentIndex ? accent : line,
                ),
              ),
            ),
          Builder(
            builder: (context) {
              final active = i == currentIndex;
              final done = !cancelled && i < currentIndex;
              final selectedColor = cancelled && active
                  ? (dark ? const Color(0xFFFFB4BC) : const Color(0xFFB63845))
                  : accent;
              return Semantics(
                selected: active,
                button: active && onStatusTap != null,
                child: Material(
                  color: active
                      ? selectedColor.withValues(alpha: dark ? .16 : .07)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: active && onStatusTap != null
                        ? () => onStatusTap!(statuses[i])
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active || done
                                  ? selectedColor
                                  : Colors.transparent,
                              border: active || done
                                  ? null
                                  : Border.all(color: line),
                            ),
                            child: active || done
                                ? Icon(
                                    cancelled
                                        ? Icons.close_rounded
                                        : done
                                        ? Icons.check_rounded
                                        : Icons.radio_button_checked,
                                    size: 16,
                                    color: dark
                                        ? const Color(0xFF21172D)
                                        : Colors.white,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: profileMuted(context),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              statuses[i].label,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active
                                    ? selectedColor
                                    : done
                                    ? profileText(context)
                                    : profileMuted(context),
                              ),
                            ),
                          ),
                          if (active)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: selectedColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
