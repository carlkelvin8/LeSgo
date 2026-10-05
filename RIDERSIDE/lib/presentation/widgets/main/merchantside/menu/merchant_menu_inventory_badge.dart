import 'package:flutter/material.dart';
import '../../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../data/data_source/dto/merchant/menu_item_dto.dart';

class MerchantMenuInventoryBadge extends StatelessWidget {
  final MenuItemDto item;

  const MerchantMenuInventoryBadge({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = MenuItemInventory.fromMenuItem(item);

    if (!inventory.trackStock && item.isAvailable) {
      return const SizedBox.shrink();
    }

    if (!item.isAvailable && !inventory.trackStock) {
      return _badge(
        context,
        label: 'Hidden',
        color: Colors.grey.shade700,
        background: Colors.grey.shade200,
      );
    }

    if (inventory.isSoldOut || (!item.isAvailable && inventory.trackStock)) {
      return _badge(
        context,
        label: 'Sold out',
        color: const Color(0xFFC62828),
        background: const Color(0xFFFFEBEE),
      );
    }

    if (inventory.isLowStock) {
      return _badge(
        context,
        label: 'Low: ${inventory.stock}',
        color: const Color(0xFFE65100),
        background: const Color(0xFFFFF3E0),
      );
    }

    return _badge(
      context,
      label: 'Stock: ${inventory.stock}',
      color: const Color(0xFF2E7D32),
      background: const Color(0xFFE8F5E9),
    );
  }

  Widget _badge(
    BuildContext context, {
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 8),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 10),
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
