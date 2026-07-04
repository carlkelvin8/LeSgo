import 'package:flutter/material.dart';
import '../../../../../../core/utils/menu_image_utils.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../common/menu_image_widget.dart';

class MerchantMenuItemCard extends StatelessWidget {
  final String name;
  final String description;
  final String price;
  final String? category;
  final String? imageUrl;
  final VoidCallback onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onDuplicateTap;
  final Widget? inventoryBadge;
  final Widget? stockControls;

  const MerchantMenuItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    this.imageUrl,
    required this.onEditTap,
    this.onDeleteTap,
    this.onDuplicateTap,
    this.inventoryBadge,
    this.stockControls,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: ResponsiveUtils.spacing(context, 70),
              height: ResponsiveUtils.spacing(context, 70),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD69A),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(context),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                          Text(
                            'PHP $price',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      height: 1.3,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (inventoryBadge != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    inventoryBadge!,
                  ],
                  SizedBox(height: ResponsiveUtils.spacing(context, 3)),
                  Row(
                    children: [
                      if (stockControls != null) ...[
                        stockControls!,
                        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                      ],
                      GestureDetector(
                        onTap: onEditTap,
                        child: Text(
                          'Edit Menu',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: const Color(0xFFC320D6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (onDeleteTap != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 8),
                          ),
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDeleteTap,
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (onDuplicateTap != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 8),
                          ),
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDuplicateTap,
                          child: Text(
                            'Duplicate',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: const Color(0xFF5F2D82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final resolved = MenuImageUtils.resolve(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return _buildPlaceholder(context);
    }

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return MenuImageWidget(
          source: imageUrl,
          fit: BoxFit.cover,
          placeholder: _buildPlaceholder(context),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.restaurant,
      size: ResponsiveUtils.spacing(context, 34),
      color: const Color(0xFF9A5A00),
    );
  }
}
