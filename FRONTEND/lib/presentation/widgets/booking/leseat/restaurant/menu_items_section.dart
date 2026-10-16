import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/entities/booking/leseat/menu_item.dart';
import 'menu_item_card.dart';

class MenuItemsSection extends StatelessWidget {
  final List<MenuItem> items;
  final String? categoryName;
  final Function(MenuItem) onAddToCart;
  final Function(MenuItem)? onItemTap;

  const MenuItemsSection({
    super.key,
    required this.items,
    this.categoryName,
    required this.onAddToCart,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.foreground(context, Colors.grey[300]!),
              ),
              const SizedBox(height: 16),
               Text(
                'No items in this category',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground(context, Color(0xFF69626F)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          item: item,
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
          onAddToCart: () => onAddToCart(item),
        );
      },
    );
  }
}
