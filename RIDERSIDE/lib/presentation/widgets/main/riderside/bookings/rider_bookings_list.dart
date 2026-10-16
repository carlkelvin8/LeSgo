import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/offline_feedback_utils.dart';
import '../../../../../../core/utils/rider_booking_mapper.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/app_localization.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../screens/main/riderside/rider_booking_detail_screen.dart';
import 'rider_booking_card.dart';
import 'rider_bookings_state_panel.dart';

class RiderBookingsList extends ConsumerWidget {
  final ValueChanged<RiderBooking>? onBookingTap;

  const RiderBookingsList({super.key, this.onBookingTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final ordersState = ref.watch(riderOrdersProvider);
    final rider = ref.watch(riderAuthProvider).user;
    final packageTier = rider?.packageTier;
    final riderCommissionRate = rider?.commissionRate;

    final tl = lang == AppLanguage.filipino;
    Future<void> refresh() async {
      await ref.read(riderWalletProvider.notifier).loadWallet();
      await ref.read(riderOrdersProvider.notifier).loadOrders();
    }

    if (ordersState.isLoading) {
      return RiderBookingsStatePanel(
        icon: Icons.route_rounded,
        loading: true,
        title: tl ? 'Kinukuha ang mga booking' : 'Checking available bookings',
        message: tl
            ? 'Sandali lang, kinukuha ang pinakabagong listahan.'
            : 'Getting the latest delivery opportunities for you.',
      );
    }
    if (ordersState.error != null) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: RiderBookingsStatePanel(
          icon: Icons.cloud_off_rounded,
          title: AppLocalization.translate('failed_to_load_bookings', lang),
          message: ordersState.error!,
          actionLabel: AppLocalization.translate('retry', lang),
          onAction: refresh,
        ),
      );
    }
    final bookings = ordersState.availableOrders
        .map(
          (order) => RiderBookingMapper.fromOrder(
            order,
            packageTier: packageTier,
            riderCommissionRate: riderCommissionRate,
          ),
        )
        .toList();

    if (bookings.isEmpty && ordersState.activeOrder == null) {
      return RefreshIndicator(
        onRefresh: refresh,
        color: const Color(0xFF5F2D82),
        child: RiderBookingsStatePanel(
          icon: Icons.delivery_dining_rounded,
          title: tl
              ? 'Handa sa susunod na delivery'
              : 'Ready for the next delivery',
          message: tl
              ? 'Wala pang available na booking. Lalabas dito ang mga bagong delivery kapag mayroon na.'
              : 'No bookings available right now. New deliveries will appear here.',
          actionLabel: AppLocalization.translate('refresh', lang),
          onAction: ordersState.isRefreshing ? null : refresh,
          loading: ordersState.isRefreshing,
        ),
      );
    }
    // Show bookings list with active order at top
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(riderWalletProvider.notifier).loadWallet();
        await ref.read(riderOrdersProvider.notifier).loadOrders();
      },
      color: const Color(0xFF5F2D82),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 24),
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        children: [
          if (ordersState.isRefreshing && !ordersState.isLoading) ...[            Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5F2D82),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    AppLocalization.translate('updating_bookings', lang),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Active Order Section (if exists)
          if (ordersState.activeOrder != null) ...[
            _buildActiveOrderCard(context, ref, ordersState.activeOrder!, lang),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 16),
                  ),
                  child: Text(
                    AppLocalization.translate('available_orders', lang),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],

          // Available Orders List
          ...bookings.asMap().entries.map((entry) {
            final index = entry.key;
            final booking = entry.value;
            final order = ordersState.availableOrders[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 12),
              ),
              child: RiderBookingCard(
                booking: booking,
                onAccept: () async {
                  final success = await ref
                      .read(riderOrdersProvider.notifier)
                      .acceptOrder(order.id);

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalization.translate(
                            'order_accepted_id',
                            lang,
                          ).replaceAll('{{id}}', '${order.id}'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    showApiErrorSnackBar(
                      context,
                      ref.read(riderOrdersProvider).error,
                      fallback: AppLocalization.translate(
                        'failed_to_accept_order',
                        lang,
                      ),
                    );
                  }
                },
                onTap: onBookingTap != null
                    ? () => onBookingTap!(booking)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(
    BuildContext context,
    WidgetRef ref,
    RiderOrder order,
    AppLanguage lang,
  ) {
    final rider = ref.read(riderAuthProvider).user;
    final booking = RiderBookingMapper.fromOrder(
      order,
      packageTier: rider?.packageTier,
      riderCommissionRate: rider?.commissionRate,
    );
    final riderEarnings = order.earningsFor(
      packageTier: rider?.packageTier,
      riderCommissionRate: rider?.commissionRate,
    );

    return GestureDetector(
      onTap: () {
        // Navigate to booking detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderBookingDetailScreen(
              booking: booking,
              currentApiStatus: order.status, // Pass the actual API status
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 8),
                    vertical: ResponsiveUtils.spacing(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ACTIVE ORDER',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                const Spacer(),
                Text(
                  'PHP ${riderEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Pickup
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.green),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Expanded(
                  child: Text(
                    order.pickupAddress,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 4)),

            // Dropoff
            Row(
              children: [
                const Icon(Icons.flag, size: 20, color: Colors.red),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Expanded(
                  child: Text(
                    order.dropoffAddress,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderBookingDetailScreen(
                        booking: booking,
                        currentApiStatus:
                            order.status, // Pass the actual API status
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(
                  AppLocalization.translate('view_details_track', lang),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

