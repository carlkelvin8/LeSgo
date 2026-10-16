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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEditTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: Color(0xFF292330),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF706878),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (category != null && category!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category!,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: Color(0xFF706878),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '₱$price',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF60318B),
                      ),
                    ),
                    if (inventoryBadge != null) ...[
                      const SizedBox(height: 8),
                      inventoryBadge!,
                    ],
                    if (stockControls != null) ...[
                      const SizedBox(height: 8),
                      stockControls!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF82778D),
              ),
            ],
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
