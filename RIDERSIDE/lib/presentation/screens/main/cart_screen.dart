import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/cart/cart_checkout_provider.dart';
import '../../provider/cart/cart_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(cartCheckoutProvider);
    final cartItems = cartState.items;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(
              showBackButton: true,
              backgroundColor: Colors.white,
              borderColor: Color(0xFFE8E8E8),
            ),
            if (cartItems.isEmpty)
              const Expanded(child: CartEmptyState())
            else
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  child: SingleChildScrollView(
                    child: CartOrderSection(
                      items: cartItems,
                      onDecrease: (itemId) {
                        ref.read(cartProvider.notifier).decrementItemQuantity(itemId);
                      },
                      onIncrease: (itemId) {
                        ref.read(cartProvider.notifier).incrementItemQuantity(itemId);
                      },
                      onAddMoreItems: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            if (cartItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context),
                ),
                child: const CartVoucherCard(),
              ),
            if (cartItems.isNotEmpty)
              CartPriceSummary(
                subtotal: checkoutState.subtotal,
                deliveryFee: checkoutState.deliveryFee,
                itemCount: checkoutState.itemCount,
                total: checkoutState.total,
              ),
          ],
        ),
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                0,
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.spacing(context, 18),
              ),
              child: PrimaryButton(
                text: 'Checkout',
                onPressed: () {
                  SnackBarUtils.showInfo(context, 'Checkout coming soon');
                },
              ),
            ),
    );
  }
}
