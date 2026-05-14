import 'package:flutter/material.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderBookingDetailInfo extends StatelessWidget {
  final RiderBooking booking;

  const RiderBookingDetailInfo({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: ResponsiveUtils.spacing(context, 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Restaurant Logo
          Container(
            width: ResponsiveUtils.spacing(context, 110),
            height: ResponsiveUtils.spacing(context, 110),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.spacing(context, 12),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              booking.logoPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.store,
                color: Colors.grey,
                size: 40,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 20)),
          // Info rows
          _InfoRow(
            label: 'Name:',
            value: booking.address.isNotEmpty ? booking.address : 'N/A',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _InfoRow(
            label: 'Contact:',
            value: (booking.customerPhone?.isNotEmpty == true) 
                ? booking.customerPhone! 
                : 'N/A',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _InfoRow(
            label: 'Address:',
            value: (booking.pickupAddress?.isNotEmpty == true) 
                ? booking.pickupAddress! 
                : 'N/A',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _InfoRow(
            label: 'PU:',
            value: (booking.pickupAddress?.isNotEmpty == true) 
                ? booking.pickupAddress! 
                : 'N/A',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _InfoRow(
            label: 'DO:',
            value: (booking.deliveryAddress?.isNotEmpty == true) 
                ? booking.deliveryAddress! 
                : 'N/A',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          if (booking.deliveryFee != null) ...[
            _InfoRow(
              label: 'Delivery Fee:',
              value: '${booking.deliveryFee}',
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ],
          _InfoRow(
            label: 'Total Billing:',
            value: '${booking.billingAmount}\n${booking.billingMethod}',
          ),
          
          if (booking.items != null && booking.items!.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _InfoRow(
              label: 'Items:',
              value: booking.items!.join('\n'),
            ),
          ],
          
          // Proof of Delivery Section
          if (booking.proofOfDeliveryUrls != null && booking.proofOfDeliveryUrls!.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Proof of Delivery:',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: booking.proofOfDeliveryUrls!.length,
              itemBuilder: (context, index) {
                // Safety check
                if (index >= booking.proofOfDeliveryUrls!.length) {
                  return const SizedBox.shrink();
                }
                
                final imageUrl = booking.proofOfDeliveryUrls![index];
                
                // Skip empty URLs
                if (imageUrl.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return GestureDetector(
                  onTap: () {
                    // Show full screen image
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black,
                        child: Stack(
                          children: [
                            Center(
                              child: InteractiveViewer(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF5F2D82),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5F2D82),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: ResponsiveUtils.spacing(context, 110),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
