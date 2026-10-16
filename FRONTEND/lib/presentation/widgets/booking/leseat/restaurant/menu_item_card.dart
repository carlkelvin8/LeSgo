import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../common/media_image.dart';
import '../../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface(context, Colors.white),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context, Color(0xFFECEAF0)), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: AppColors.surface(context, Color(0xFFF5F4F7)),
                    child: MediaImage(
                      imagePath: item.imagePath,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: AppColors.surface(context, Color(0xFFF5F4F7)),
                        child:  Center(
                          child: Icon(
                            Icons.restaurant_menu,
                            color: AppColors.foreground(context, Color(0xFFA49BAE)),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        item.name,
                        style:  TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Color(0xFF302B36)),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style:  TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            color: AppColors.foreground(context, Color(0xFF918A98)),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Price and Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '₱${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5F2D82),
                              ),
                            ),
                          ),
                          if (onAddToCart != null)
                            Material(
                              color: AppColors.accent(context, Color(0xFF5F2D82)),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onAddToCart,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.add,
                                    color: AppColors.onAccent(context),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
