import 'package:flutter/material.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderBookingStatusButton extends StatelessWidget {
  final BookingStatus status;
  final bool isActive;
  final VoidCallback? onTap;

  const RiderBookingStatusButton({
    super.key,
    required this.status,
    required this.isActive,
    this.onTap,
  });

  static LinearGradient _gradient(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return const LinearGradient(
          colors: [Color(0xFFF0F0F0), Color(0xFFDDDDDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.cooking:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFB3B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.forPickUp:
        return const LinearGradient(
          colors: [Color(0xFFFFE57F), Color(0xFFFFF3B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.forDelivery:
        return const LinearGradient(
          colors: [Color(0xFFFFD740), Color(0xFFFFF176)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.delivered:
        return const LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.toBuy:
        return const LinearGradient(
          colors: [Color(0xFF9B59F0), Color(0xFF5F2D82)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case BookingStatus.onTheWay:
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.onTheWayGoing:
        return const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.driverHasArrived:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.complete:
        return const LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BookingStatus.cancelled:
        return const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFEF9A9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static Color _textColor(BookingStatus s) {
    return const Color(0xFF2D2D2D);
  }

  @override
  Widget build(BuildContext context) {
    final upload = status.uploadLabel;
    final labelFontSize = ResponsiveUtils.fontSize(context, 12);
    final subFontSize = ResponsiveUtils.fontSize(context, 10);

    return Semantics(
      button: true,
      enabled: isActive && onTap != null,
      label: isActive && onTap != null
          ? 'Update booking to ${status.label}'
          : status.label,
      child: GestureDetector(
        onTap: isActive ? onTap : null,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: ResponsiveUtils.spacing(context, 88),
            minWidth: ResponsiveUtils.spacing(context, 108),
          ),
          margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
          decoration: BoxDecoration(
            gradient: _gradient(status),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 14),
            ),
            border: isActive
                ? Border.all(color: const Color(0xFF5F2D82), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 12),
            horizontal: ResponsiveUtils.spacing(context, 8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status.label.replaceAll('\n', ' '),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w700,
                  color: _textColor(status),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
              if (upload != null) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  upload,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: subFontSize,
                    fontWeight: FontWeight.w500,
                    color: _textColor(status).withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
