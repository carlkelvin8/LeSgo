import 'package:flutter/material.dart';
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
