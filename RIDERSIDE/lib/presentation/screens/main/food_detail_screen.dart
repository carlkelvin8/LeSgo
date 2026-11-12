import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'cart_screen.dart';
import '../../provider/cart/cart_provider.dart';
import '../../provider/main/merchantside/merchant_food_detail_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/dark_aware_colors.dart';

class FoodDetailScreen extends ConsumerWidget {
  final String foodName;
  final String? foodImage;
  final String price;
  final String description;
  final List<MerchantFoodSizeOption> sizes;
  final List<MerchantFoodSizeOption> flavors;
  final List<MerchantFoodSizeOption> addons;
  final int? menuItemId;

  const FoodDetailScreen({
    super.key,
    required this.foodName,
    this.foodImage,
    required this.price,
    required this.description,
    required this.sizes,
    this.flavors = const [],
    this.addons = const [],
    this.menuItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedDescription = description;

    final input = MerchantFoodDetailInput(
      foodName: foodName,
      price: price,
      sizes: sizes,
      flavors: flavors,
      addons: addons,
    );
    final detailState = ref.watch(merchantFoodDetailProvider(input));
    final detailNotifier = ref.read(merchantFoodDetailProvider(input).notifier);

    return Scaffold(
      backgroundColor: context.bg(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(showBackButton: true),
            Expanded(
              child: MerchantFoodDetailContent(
                foodName: foodName,
                foodImage: foodImage,
                displayPrice: price,
                description: resolvedDescription,
                sizes: detailState.sizes,
                selectedSize: detailState.selectedSize,
                onSelectSize: detailNotifier.selectSize,
                flavors: detailState.flavors,
                selectedFlavor: detailState.selectedFlavor,
                onSelectFlavor: detailNotifier.selectFlavor,
                addons: detailState.addons,
                selectedAddons: detailState.selectedAddons,
                onToggleAddon: detailNotifier.toggleAddon,
              ),
            ),
            MerchantFoodDetailQuantityBar(
              quantity: detailState.quantity,
              onDecrease: detailNotifier.decrementQuantity,
              onIncrease: detailNotifier.incrementQuantity,
            ),
            MerchantFoodDetailSubtotalRow(subtotal: detailState.subtotal),
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: PrimaryButton(
                text: 'ADD ORDER',
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(
                        name: foodName,
                        size: detailState.optionsLabel,
                        unitPrice: detailState.unitPrice,
                        quantity: detailState.quantity,
                        menuItemId: menuItemId,
                        selectedOptions: detailState.selectedOptions,
                      );

                  SnackBarUtils.showSuccess(context, '$foodName added to cart!');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
