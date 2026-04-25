import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/cart/cart_provider.dart';
import '../../../core/utils/responsive_utils.dart';

class CartIcon extends ConsumerWidget {
  final VoidCallback? onTap;

  const CartIcon({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.itemCount;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          // Cart icon
          Icon(
            Icons.shopping_cart_outlined,
            size: ResponsiveUtils.imageHeight(context, 26),
            color: const Color(0xFF5F2D82),
          ),
          // Badge with item count
          if (itemCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.fontSize(context, 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
