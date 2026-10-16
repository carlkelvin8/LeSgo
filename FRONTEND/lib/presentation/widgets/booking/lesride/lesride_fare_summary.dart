import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/booking/lesride_provider.dart';

class LesrideFareSummary extends ConsumerWidget {
  const LesrideFareSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(lesrideProvider.select((s) => s.isLoadingFare));
    final fare = ref.watch(lesrideProvider.select((s) => s.fareEstimate));
    final error = ref.watch(lesrideProvider.select((s) => s.fareError));

    if (fare == null && !isLoading && error == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fare Estimate',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error == null ? AppColors.foreground(context, Colors.grey.shade200) : Colors.red.shade200,
            ),
          ),
          child: isLoading
              ? _loading(context)
              : error != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    TextButton.icon(
                      onPressed: () => ref
                          .read(lesrideProvider.notifier)
                          .fetchFareEstimate(),
                      icon: const Icon(Icons.refresh, size: 17),
                      label: const Text('Retry fare estimate'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _row(context, 'Base fare (first 3 km)', fare!.baseFare),
                    if (fare.distanceFare > 0)
                      _row(context, 'Additional distance', fare.distanceFare),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 8),
                      ),
                      child: Divider(color: AppColors.border(context, Colors.grey.shade300), height: 1),
                    ),
                    _row(context, 'Total', fare.total, isTotal: true),
                    SizedBox(height: ResponsiveUtils.spacing(context, 7)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${fare.distanceKm.toStringAsFixed(1)} km  •  ₱15/km after 3 km',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          color: AppColors.foreground(context, Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _loading(BuildContext context) {
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
            color: AppColors.foreground(context, Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.foreground(context, Colors.black87),
              ),
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.foreground(context, Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
