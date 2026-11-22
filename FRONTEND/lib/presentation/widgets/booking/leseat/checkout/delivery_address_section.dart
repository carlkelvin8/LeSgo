import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class DeliveryAddressSection extends StatelessWidget {
  final String address;
  final VoidCallback? onTap;

  const DeliveryAddressSection({super.key, required this.address, this.onTap});

  /// True when there is no usable delivery address to show.
  bool get isMissing => address.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Material(
        color: isMissing ? OrderDesign.tint(context) : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: OrderDesign.cardRadius,
          side: BorderSide(color: OrderDesign.line(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                OrderIcon(
                  isMissing
                      ? Icons.add_location_alt_outlined
                      : Icons.location_on_outlined,
                  mint: !isMissing,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery address',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isMissing ? 'Add a delivery address' : address,
                        style: TextStyle(
                          color: isMissing
                              ? OrderDesign.accent(context)
                              : colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    isMissing ? 'Add' : 'Edit',
                    style: TextStyle(
                      color: OrderDesign.accent(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: OrderDesign.accent(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
