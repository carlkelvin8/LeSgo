import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../provider/main/booking/lesgo_provider.dart';

/// Displays the fare breakdown (base fee, distance fee, total) in the LesGo
/// booking panel after the user confirms pickup and drop-off locations.
class LesgoFareSummary extends ConsumerWidget {
  const LesgoFareSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(lesgoProvider.select((s) => s.isLoadingFare));
    final fare = ref.watch(lesgoProvider.select((s) => s.fareEstimate));
    final discount = ref.watch(lesgoProvider.select((s) => s.discount));

    // Don't render anything if we haven't fetched yet
    if (fare == null && !isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fare Estimate',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: isLoading
              ? _buildLoadingState(context)
              : _buildFareDetails(context, fare!, discount),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
        Text(
          'Calculating fare...',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFareDetails(
    BuildContext context,
    FareBreakdownResult fare,
    double discount,
  ) {
    final total = fare.total - discount;
    final displayTotal = total > 0 ? total : fare.total;

    return Column(
      children: [
        _row(context, 'Base Fee', fare.baseFare),
        if (fare.distanceFare > 0)
          _row(context, 'Distance Fee', fare.distanceFare),
        if (fare.serviceFee > 0)
          _row(context, 'Service Fee', fare.serviceFee),
        if (fare.weightSurcharge > 0)
          _row(context, 'Weight Surcharge', fare.weightSurcharge),
        if (discount > 0) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          _row(context, 'Voucher Discount', -discount, isDiscount: true),
        ],
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 8),
          ),
          child: Divider(color: Colors.grey.shade300, height: 1),
        ),
        _row(context, 'Total', displayTotal, isTotal: true),
        if (fare.estimatedDurationMinutes > 0) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              SizedBox(width: ResponsiveUtils.spacing(context, 4)),
              Text(
                'Est. ${fare.estimatedDurationMinutes.round()} min  •  ${fare.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final color = isDiscount
        ? Colors.green.shade700
        : isTotal
            ? const Color(0xFF5F2D82)
            : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}₱${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
