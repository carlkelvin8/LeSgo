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
    }
  }

  static Color _textColor(BookingStatus s) {
    return const Color(0xFF2D2D2D);
  }

  @override
  Widget build(BuildContext context) {
    final upload = status.uploadLabel;

    return GestureDetector(
      onTap: () {
        print('🔘 Status button tapped: ${status.label}');
        if (onTap != null) {
          print('✅ Calling onTap handler');
          onTap!();
        } else {
          print('❌ onTap is null!');
        }
      },
      child: Container(
        margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 5)),
        constraints: BoxConstraints(
          minHeight: ResponsiveUtils.spacing(context, 72),
        ),
        decoration: BoxDecoration(
          gradient: _gradient(status),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.spacing(context, 14),
          horizontal: ResponsiveUtils.spacing(context, 10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w700,
                color: _textColor(status),
              ),
              textAlign: TextAlign.center,
            ),
            if (upload != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
              Text(
                upload,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  fontWeight: FontWeight.w400,
                  color: _textColor(status).withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
