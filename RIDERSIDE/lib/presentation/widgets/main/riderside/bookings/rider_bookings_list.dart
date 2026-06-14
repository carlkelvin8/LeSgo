import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/offline_feedback_utils.dart';
import '../../../../../../core/utils/rider_booking_mapper.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../screens/main/riderside/rider_booking_detail_screen.dart';
import '../wallet/rider_wallet_low_balance_banner.dart';
import 'rider_booking_card.dart';

class RiderBookingsList extends ConsumerWidget {
  final ValueChanged<RiderBooking>? onBookingTap;

  const RiderBookingsList({super.key, this.onBookingTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(riderOrdersProvider);
    final wallet = ref.watch(riderWalletProvider);
    final rider = ref.watch(riderAuthProvider).user;
    final packageTier = rider?.packageTier;
    final riderCommissionRate = rider?.commissionRate;

    // Show loading indicator
    if (ordersState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
        ),
      );
    }

    // Show error message
    if (ordersState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'Failed to load bookings',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              ordersState.error!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            ElevatedButton(
              onPressed: () => ref.read(riderOrdersProvider.notifier).loadOrders(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              child: const Text('Retry'),
            ),
          ],
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

    // Show empty state (only if no active order and no available orders)
    if (bookings.isEmpty && ordersState.activeOrder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'No available bookings',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'New bookings will appear here',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            ElevatedButton.icon(
              onPressed: () => ref.read(riderOrdersProvider.notifier).loadOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
            ),
          ],
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 24),
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        children: [
          if (ordersState.isRefreshing && !ordersState.isLoading) ...[
            Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5F2D82),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Updating bookings...',
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
          if (wallet.showLowBalanceWarning) ...[
            RiderWalletLowBalanceBanner(balance: wallet.balance),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ],
          // Active Order Section (if exists)
          if (ordersState.activeOrder != null) ...[
            _buildActiveOrderCard(context, ref, ordersState.activeOrder!),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                  child: Text(
                    'Available Orders',
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
              padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
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
                        content: Text('Order #${order.id} accepted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final error = ref.read(riderOrdersProvider).error ??
                        'Failed to accept order';
                    showApiErrorSnackBar(
                      context,
                      error,
                      fallback: 'Failed to accept order',
                    );
                  }
                },
                onTap: onBookingTap != null ? () => onBookingTap!(booking) : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, WidgetRef ref, RiderOrder order) {
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
                Icon(Icons.location_on, size: 20, color: Colors.green),
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
                Icon(Icons.flag, size: 20, color: Colors.red),
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
                        currentApiStatus: order.status, // Pass the actual API status
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.visibility, size: 18),
                label: Text('View Details & Track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 12)),
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
