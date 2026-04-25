import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final statuses = booking.category.statuses;
    final rows = <Widget>[];

    for (int i = 0; i < statuses.length; i += 2) {
      final isLastOdd = i + 1 >= statuses.length;

      rows.add(
        isLastOdd
            ? Row(
                children: [
                  Expanded(
                    child: RiderBookingStatusButton(
                      status: statuses[i],
                      isActive: statuses[i] == currentStatus,
                      onTap: onStatusTap != null ? () => onStatusTap!(statuses[i]) : null,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: RiderBookingStatusButton(
                      status: statuses[i],
                      isActive: statuses[i] == currentStatus,
                      onTap: onStatusTap != null ? () => onStatusTap!(statuses[i]) : null,
                    ),
                  ),
                  Expanded(
                    child: RiderBookingStatusButton(
                      status: statuses[i + 1],
                      isActive: statuses[i + 1] == currentStatus,
                      onTap: onStatusTap != null ? () => onStatusTap!(statuses[i + 1]) : null,
                    ),
                  ),
                ],
              ),
      );
    }

    return Column(children: rows);
  }
}
