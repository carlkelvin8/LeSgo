import 'package:flutter/material.dart';
import '../../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../data/data_source/dto/merchant/menu_item_dto.dart';

class MerchantMenuStockControls extends StatelessWidget {
  final MenuItemDto item;
  final Future<void> Function(int newStock) onStockChanged;

  const MerchantMenuStockControls({
    super.key,
    required this.item,
    required this.onStockChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = MenuItemInventory.fromMenuItem(item);
    if (!inventory.trackStock) return const SizedBox.shrink();

    final currentStock = inventory.stock ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          context,
          icon: Icons.remove,
          onTap: currentStock > 0
              ? () => onStockChanged(currentStock - 1)
              : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 6),
          ),
          child: Text(
            '$currentStock',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5F2D82),
            ),
          ),
        ),
        _button(
          context,
          icon: Icons.add,
          onTap: () => onStockChanged(currentStock + 1),
        ),
      ],
    );
  }

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: ResponsiveUtils.spacing(context, 28),
        height: ResponsiveUtils.spacing(context, 28),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade200 : const Color(0xFFF7F2FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null
                ? Colors.grey.shade300
                : const Color(0xFFE8D9F5),
          ),
        ),
        child: Icon(
          icon,
          size: ResponsiveUtils.fontSize(context, 16),
          color: onTap == null
              ? Colors.grey.shade500
              : const Color(0xFF5F2D82),
        ),
      ),
    );
  }
}
