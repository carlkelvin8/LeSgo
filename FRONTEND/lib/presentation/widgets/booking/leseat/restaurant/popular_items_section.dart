import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/menu_item.dart';
import 'menu_item_card.dart';

class PopularItemsSection extends StatelessWidget {
  final List<MenuItem> items;
  final Function(MenuItem) onAddToCart;
  final Function(MenuItem)? onItemTap;

  const PopularItemsSection({
    super.key,
    required this.items,
    required this.onAddToCart,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menu Items List

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
