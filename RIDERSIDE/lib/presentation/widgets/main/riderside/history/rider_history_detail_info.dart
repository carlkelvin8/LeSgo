import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderHistoryDetailInfo extends StatelessWidget {
  final Map<String, String> bookingData;

  const RiderHistoryDetailInfo({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Booking ID
        Text(
          bookingData['id'] ?? '',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 4)),

        // Restaurant Name
        Text(
          bookingData['restaurantName'] ?? '',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 2)),

        // Address
        Text(
          bookingData['address'] ?? '',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),

        // Customer Details
        _buildDetailRow(context, '', bookingData['referenceNumber'] ?? ''),
        _buildDetailRow(context, 'Name: ', bookingData['customerName'] ?? ''),
        _buildDetailRow(
          context,
          'Contact: ',
          bookingData['customerContact'] ?? '',
        ),
        _buildDetailRow(
          context,
          'Address: ',
          bookingData['address'] ?? '',
        ), // From screenshot it uses the delivery address here too
        _buildDetailRow(context, 'PU: ', bookingData['pu'] ?? ''),
        _buildDetailRow(context, 'DO: ', bookingData['do'] ?? ''),
        _buildDetailRow(context, 'Billing: ', bookingData['price'] ?? ''),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    if (label.isEmpty && value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 4)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: Colors.black87,
          ),
          children: [
            if (label.isNotEmpty)
              TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: label.isEmpty ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
