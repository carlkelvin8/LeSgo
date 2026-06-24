import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../../../core/utils/app_localization.dart';
import 'rider_swipe_accept_button.dart';

class RiderBookingCard extends ConsumerWidget {
  final RiderBooking booking;
  final VoidCallback onAccept;
  final VoidCallback? onTap;

  const RiderBookingCard({
    super.key,
    required this.booking,
    required this.onAccept,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Semantics(
      label:
          '${AppLocalization.translate('booking_from', lang)} ${booking.restaurantName}. ${booking.address}. Earnings ${booking.earnings ?? 'unknown'} pesos.',
      button: onTap != null,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.spacing(context, 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant / Passenger Logo
              Container(
                width: ResponsiveUtils.spacing(context, 60),
                height: ResponsiveUtils.spacing(context, 60),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  booking.logoPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.store, color: Colors.grey),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              // Detail Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.restaurantName,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      booking.address,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),              ),            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          // Swipe to accept slider
          RiderSwipeAcceptButton(onAccepted: onAccept),
        ],
      ),
    ),
    ),
    );
  }
}

