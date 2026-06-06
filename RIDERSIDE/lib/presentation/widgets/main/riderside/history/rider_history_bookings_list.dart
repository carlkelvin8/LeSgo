import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../screens/main/riderside/rider_booking_detail_screen.dart';
import 'rider_history_booking_card.dart';

/// Pure presentational bookings list — receives RiderBooking objects
class RiderHistoryBookingsList extends StatelessWidget {
  final List<RiderBooking> bookings;

  const RiderHistoryBookingsList({
    super.key,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 40)),
          child: Text(
            'No bookings found',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        top: ResponsiveUtils.spacing(context, 4),
        bottom: ResponsiveUtils.spacing(context, 24),
      ),
      itemCount: bookings.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        
        // Determine status display
        String statusLabel;
        Color statusColor;
        Color statusBackgroundColor;
        
        if (booking.currentStatus == BookingStatus.complete ||
            booking.currentStatus == BookingStatus.delivered) {
          statusLabel = 'Completed';
          statusColor = const Color(0xFF4CAF50);
          statusBackgroundColor = const Color(0xFFE8F5E9);
        } else if (booking.currentStatus == BookingStatus.cancelled) {
          statusLabel = 'Cancelled';
          statusColor = const Color(0xFFF44336);
          statusBackgroundColor = const Color(0xFFFFEBEE);
        } else {
          statusLabel = 'Active';
          statusColor = const Color(0xFFFF9800);
          statusBackgroundColor = const Color(0xFFFFF3E0);
        }
        
        return GestureDetector(
          onTap: () {
            // Navigate to detail screen with the booking
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RiderBookingDetailScreen(
                  booking: booking,
                  currentApiStatus: _mapBookingStatusToApiStatus(booking.currentStatus),
                ),
              ),
            );
          },
          child: RiderHistoryBookingCard(
            bookingId: booking.id,
            restaurantName: booking.restaurantName,
            address: booking.deliveryAddress ?? booking.address,
            price: booking.billingAmount.replaceFirst('Order total ', ''),
            status: statusLabel,
            statusColor: statusColor,
            statusBackgroundColor: statusBackgroundColor,
            proofImageCount: booking.proofOfDeliveryUrls?.length,
          ),
        );
      },
    );
  }
  
  // Helper to map BookingStatus to API status string
  String _mapBookingStatusToApiStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.complete:
      case BookingStatus.delivered:
        return 'completed';
      case BookingStatus.onTheWayGoing:
      case BookingStatus.forDelivery:
      case BookingStatus.forPickUp:
        return 'picked_up';
      case BookingStatus.onTheWay:
      case BookingStatus.cooking:
      case BookingStatus.toBuy:
        return 'accepted';
      case BookingStatus.driverHasArrived:
        return 'driver_arrived_at_pickup';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.cancelled:
        return 'cancelled';
      default:
        return 'accepted';
    }
  }
}
