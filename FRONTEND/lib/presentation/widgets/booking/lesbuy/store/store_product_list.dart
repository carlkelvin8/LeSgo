import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/product.dart';

class StoreProductList extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAddToCart;
  final Function(Product)? onItemTap;

  const StoreProductList({
    super.key,
    required this.products,
    required this.onAddToCart,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 32)),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: ResponsiveUtils.fontSize(context, 48),
                color: AppColors.foreground(context, Colors.grey[400]!),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Text(
                'No items found',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  color: AppColors.foreground(context, Colors.grey[600]!),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context, Colors.grey[200]!)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (onItemTap != null) {
                  onItemTap!(product);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: ResponsiveUtils.cardImageSize(context, 80),
                        height: ResponsiveUtils.cardImageSize(context, 80),
                        color: AppColors.surface(context, Colors.grey[100]!),
                        child: Image.asset(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: AppColors.foreground(context, Colors.grey[400]!),
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground(context, Colors.black87),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: AppColors.foreground(context, Colors.grey[600]!),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₱${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 14),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
