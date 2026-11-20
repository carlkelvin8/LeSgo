import 'package:lesgo/core/theme/app_colors.dart';
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
    final card = Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context, Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver this order to:',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                if (isMissing)
                  Row(
                    children: [
                      Icon(
                        Icons.add_location_alt_outlined,
                        size: ResponsiveUtils.fontSize(context, 18),
                        color: AppColors.accent(
                          context,
                          const Color(0xFF5F2D82),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                      Flexible(
                        child: Text(
                          'Add a delivery address',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent(
                              context,
                              const Color(0xFF5F2D82),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    address,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground(context, Colors.black87),
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            Text(
              isMissing ? 'Add' : 'Edit',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.foreground(context, Colors.grey[600]!),
              size: ResponsiveUtils.fontSize(context, 24),
            ),
          ],
        ],
      ),
    );

    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: card,
    );

    if (onTap == null) return padded;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      ),
    );
  }
}
