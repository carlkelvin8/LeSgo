import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/cart/cart_checkout_provider.dart';
import '../../provider/cart/cart_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final addressController = TextEditingController();
    String paymentMethod = 'cash';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                  hintText: 'Enter delivery address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => paymentMethod = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );

    if (proceed != true || !context.mounted) return;

    final address = addressController.text.trim();
    addressController.dispose();

    if (address.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a delivery address');
      return;
    }

    final success = await ref.read(cartCheckoutStateProvider.notifier).checkout(
          deliveryAddress: address,
          paymentMethod: paymentMethod,
        );

    if (!context.mounted) return;

    if (success) {
      final orderId = ref.read(cartCheckoutStateProvider).orderId;
      SnackBarUtils.showSuccess(
        context,
        orderId != null ? 'Order #$orderId placed successfully!' : 'Order placed successfully!',
      );
      Navigator.pop(context);
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(cartCheckoutStateProvider).errorMessage ?? 'Checkout failed',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutSummary = ref.watch(cartCheckoutProvider);
    final checkoutState = ref.watch(cartCheckoutStateProvider);
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
                subtotal: checkoutSummary.subtotal,
                deliveryFee: checkoutSummary.deliveryFee,
                itemCount: checkoutSummary.itemCount,
                total: checkoutSummary.total,
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
                text: checkoutState.isSubmitting ? 'Placing order...' : 'Checkout',
                isLoading: checkoutState.isSubmitting,
                onPressed: checkoutState.isSubmitting ? null : () => _checkout(context, ref),
              ),
            ),
    );
  }
}
