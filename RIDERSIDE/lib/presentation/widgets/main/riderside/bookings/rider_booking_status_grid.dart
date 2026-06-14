import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import 'rider_booking_status_button.dart';

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

  List<BookingStatus> get _statuses {
    final steps = List<BookingStatus>.from(booking.category.statuses);
    if (currentStatus == BookingStatus.cancelled &&
        !steps.contains(BookingStatus.cancelled)) {
      steps.add(BookingStatus.cancelled);
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _statuses;
    final chipWidth = ResponsiveUtils.spacing(context, 118);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final status in statuses) ...[
            SizedBox(
              width: chipWidth,
              child: RiderBookingStatusButton(
                status: status,
                isActive: status == currentStatus,
                onTap: onStatusTap != null ? () => onStatusTap!(status) : null,
              ),
            ),
            if (status != statuses.last)
              SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          ],
        ],
      ),
    );
  }
}
