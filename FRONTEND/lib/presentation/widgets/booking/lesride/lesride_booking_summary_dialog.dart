import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../../provider/main/booking/lesride_provider.dart';
import '../../../provider/auth/auth_provider.dart';

class LesrideBookingSummaryDialog extends ConsumerWidget {
  const LesrideBookingSummaryDialog({super.key});

  String _formatAddress(LocationAddress address) {
    final parts = <String>[];

    if (address.houseNumberStreet != null &&
        address.houseNumberStreet!.isNotEmpty) {
      parts.add(address.houseNumberStreet!);
    }

    if (address.subdivisionBarangay != null &&
        address.subdivisionBarangay!.isNotEmpty) {
      parts.add(address.subdivisionBarangay!);
    }

    if (address.cityProvince != null && address.cityProvince!.isNotEmpty) {
      parts.add(address.cityProvince!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  // Format duration from seconds to readable format
  static String formatDuration(int? durationInSeconds) {
    if (durationInSeconds == null) return 'N/A';
    final minutes = (durationInSeconds / 60).ceil();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0 ? '$hours h $remainingMinutes min' : '$hours h';
  }

  static String formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'cod':
        return 'Cash';
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'wallet':
        return 'LesPay Wallet';
      case 'card':
        return 'Card';
      case 'xendit':
        return 'Online Payment';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(lesrideLocationProvider);
    final lesrideState = ref.watch(lesrideProvider);
    final authState = ref.watch(authProvider);

    final distance = locationState.distanceInKm ?? 0.0;
    final duration = locationState.durationInSeconds;
    final fare = lesrideState.fareEstimate;
    const discount = 0.0;
    final totalFare = fare?.total ?? 0.0;

    final pickupAddress = locationState.pickupAddress;
    final destinationAddress = locationState.destinationAddress;

    final pickupText = pickupAddress != null
        ? _formatAddress(pickupAddress)
        : 'Pickup location not set';

    final destinationText = destinationAddress != null
        ? _formatAddress(destinationAddress)
        : 'Destination not set';

    final passengerName = authState.user?.name ?? 'Guest';
    final paymentMethod = formatPaymentMethod(lesrideState.paymentMethod);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                  child: Text(
                    'BOOKING SUMMARY',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trip Details
                        _buildDetailRow(context, 'Pickup location', pickupText),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Destination',
                          destinationText,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Distance',
                          distance > 0
                              ? '${distance.toStringAsFixed(1)} km'
                              : '0.0 km',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Travel time',
                          formatDuration(duration),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                        // Service Details
                        _buildDetailRow(
                          context,
                          'Vehicle Type',
                          lesrideState.selectedVehicle.label,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Payment method',
                          paymentMethod,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Passenger Name',
                          passengerName,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(context, 'Note', 'No notes added'),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                        // Dotted Divider
                        _buildDottedDivider(context),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                        // Fare Breakdown
                        _buildDetailRow(
                          context,
                          'Voucher',
                          'No Voucher Applied',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        _buildDetailRow(
                          context,
                          'Discount',
                          'PHP ${discount.toStringAsFixed(2)}',
                        ),
                        if (fare != null) ...[
                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 12),
                          ),
                          _buildDetailRow(
                            context,
                            'Base fare (first 3 km)',
                            'PHP ${fare.baseFare.toStringAsFixed(2)}',
                          ),
                          if (fare.distanceFare > 0) ...[
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 12),
                            ),
                            _buildDetailRow(
                              context,
                              'Additional distance',
                              'PHP ${fare.distanceFare.toStringAsFixed(2)}',
                            ),
                          ],
                        ],
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Fare',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'PHP ${totalFare.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                // Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 20),
                  ),
                  child: Column(
                    children: [
                      // Book Button
                      Container(
                        width: double.infinity,
                        height: ResponsiveUtils.buttonHeight(context),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F2D82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(true);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Text(
                                'Book',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    16,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Cancel Text Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.spacing(context, 8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedDivider(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(),
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }
}

// Custom painter for dotted line
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const double dashWidth = 5;
    const double dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
