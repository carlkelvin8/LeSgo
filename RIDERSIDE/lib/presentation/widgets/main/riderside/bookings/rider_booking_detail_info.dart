import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../../../core/utils/media_url_utils.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderBookingDetailInfo extends StatelessWidget {
  final RiderBooking booking;

  const RiderBookingDetailInfo({super.key, required this.booking});

  bool get _isFoodOrder =>
      booking.category == BookingCategory.lesEat ||
      booking.category == BookingCategory.lesBuy;

  Future<void> _callCustomer(BuildContext context) async {
    final phone = booking.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hp,
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ServiceBadge(category: booking.category),
              const Spacer(),
              Text(
                'Order #${booking.id}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          _SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isFoodOrder ? Icons.storefront : Icons.local_taxi,
                    color: const Color(0xFF5F2D82),
                    size: 28,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isFoodOrder ? 'Pickup' : 'Trip',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        booking.restaurantName,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                Text(
                  booking.customerName,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (booking.customerPhone != null &&
                    booking.customerPhone!.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  InkWell(
                    onTap: () => _callCustomer(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.phone,
                              size: 18, color: const Color(0xFF5F2D82)),
                          SizedBox(
                              width: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            booking.customerPhone!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5F2D82),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  Text(
                    'No contact number on file',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _SectionCard(
            child: Column(
              children: [
                _RouteRow(
                  icon: Icons.circle,
                  iconColor: Colors.green,
                  label: _isFoodOrder ? 'Pick up from' : 'Pick up',
                  value: booking.pickupAddress ?? 'N/A',
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: ResponsiveUtils.spacing(context, 11),
                  ),
                  child: Row(
                    children: [
                      Container(width: 2, height: 20, color: Colors.grey.shade300),
                    ],
                  ),
                ),
                _RouteRow(
                  icon: Icons.place,
                  iconColor: Colors.red,
                  label: 'Deliver to',
                  value: booking.deliveryAddress ?? booking.address,
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking.itemsSubtotal != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items subtotal',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        booking.itemsSubtotal!.replaceFirst('Items subtotal ', ''),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                ],
                if (booking.deliveryFee != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery fee',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        booking.deliveryFee!
                            .replaceAll('Delivery fee ', '')
                            .replaceAll('LesPay hold (shipping only) ', ''),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order total',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      booking.billingAmount.replaceFirst('Order total ', ''),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  booking.billingMethod,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
                if (booking.earnings != null) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    booking.earnings!,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (booking.items != null && booking.items!.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  const Divider(height: 1),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Text(
                    'Items',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  ...booking.items!.expand((item) {
                    final lines = item.split('\n');
                    return lines.map(
                      (line) => Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveUtils.spacing(context, 6),
                        ),
                        child: Text(
                          line.trimLeft().startsWith('Size:') ||
                                  line.trimLeft().startsWith('Flavor:') ||
                                  line.trimLeft().startsWith('Add-ons:')
                              ? '   $line'
                              : '• $line',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            color: line.trimLeft().startsWith('Size:') ||
                                    line.trimLeft().startsWith('Flavor:') ||
                                    line.trimLeft().startsWith('Add-ons:')
                                ? Colors.orange.shade700
                                : Colors.black87,
                            fontStyle: line.contains('Size:') ||
                                    line.contains('Flavor:') ||
                                    line.contains('Add-ons:')
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          if (booking.proofOfDeliveryUrls != null &&
              booking.proofOfDeliveryUrls!.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _ProofGrid(urls: booking.proofOfDeliveryUrls!),
          ],
        ],
      ),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  final BookingCategory category;

  const _ServiceBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 12),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5F2D82),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProofGrid extends StatelessWidget {
  final List<String> urls;

  const _ProofGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proof of delivery',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final imageUrl =
                MediaUrlUtils.resolveProofImageUrl(urls[index]) ?? urls[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
