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
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEditTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveUtils.spacing(context, 60),
                  height: ResponsiveUtils.spacing(context, 60),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                                fontSize: ResponsiveUtils.fontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF302B36),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            '₱$price',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12.5),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8054A2),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 3)),
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 10.5),
                            height: 1.4,
                            color: const Color(0xFF918A98),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (category != null && category!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 8),
                            vertical: ResponsiveUtils.spacing(context, 3),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 9.5),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8054A2),
                            ),
                          ),
                        ),
                      ],
                      if (inventoryBadge != null) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                        inventoryBadge!,
                      ],
                      if (stockControls != null) ...[
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        stockControls!,
                      ],
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Icon(
                  Icons.chevron_right_rounded,
                  size: ResponsiveUtils.fontSize(context, 18),
                  color: const Color(0xFF8F8798),
                ),
              ],
            ),
          ),
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
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF8054A2),
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
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        size: ResponsiveUtils.spacing(context, 24),
        color: const Color(0xFFA49BAE),
      ),
    );
  }
}
