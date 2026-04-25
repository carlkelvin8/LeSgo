import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
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
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 32)),
          child: Text(
            'No items in this category',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menu Items List
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.spacing(context, 16),
            ),
            child: MenuItemCard(
              item: item,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            ),
          ),
        ),
      ],
    );
  }
}
