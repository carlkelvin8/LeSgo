import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../common/menu_image_widget.dart';

class MerchantOrderCard extends StatelessWidget {
  final String orderId;
  final String itemName;
  final String price;
  final String customerName;
  final String address;
  final String? imageUrl;
  final String? specialInstructionsPreview;
  final Widget? trailingBadge;

  const MerchantOrderCard({
    super.key,
    required this.orderId,
    required this.itemName,
    required this.price,
    required this.customerName,
    required this.address,
    this.imageUrl,
    this.specialInstructionsPreview,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 68),
            height: ResponsiveUtils.spacing(context, 68),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: MenuImageWidget(
              source: imageUrl,
              fit: BoxFit.cover,
              placeholder: Icon(
                Icons.restaurant,
                color: const Color(0xFFCCCCCC),
                size: ResponsiveUtils.fontSize(context, 28),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        orderId,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 9),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      "PHP $price",
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 10),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Text(
                  itemName,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Text(
                  customerName,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 10),
                    color: Colors.black,
                  ),
                ),
                Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 10),
                    color: Colors.black,
                  ),
                ),
                if (specialInstructionsPreview != null &&
                    specialInstructionsPreview!.trim().isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 8),
                      vertical: ResponsiveUtils.spacing(context, 5),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: ResponsiveUtils.fontSize(context, 11),
                          color: Colors.orange.shade800,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        Expanded(
                          child: Text(
                            specialInstructionsPreview!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 9),
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (trailingBadge != null) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                  trailingBadge!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
