import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class LesrideLocationTile extends StatelessWidget {
  const LesrideLocationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isLoading = false,
    this.isDestination = false,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isLoading;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 8, 3),
      child: Row(
        children: [
          OrderIcon(
            isDestination
                ? Icons.location_on_outlined
                : Icons.my_location_rounded,
            mint: !isDestination,
            size: 34,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isLoading) ...[
                      const MapLoadingIndicator(size: 16),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          trailing,
        ],
      ),
    );
  }
}
