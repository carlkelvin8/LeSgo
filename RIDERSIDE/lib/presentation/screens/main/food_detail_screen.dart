import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'cart_screen.dart';
import '../../provider/cart/cart_provider.dart';
import '../../provider/main/merchantside/merchant_food_detail_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class FoodDetailScreen extends ConsumerWidget {
  final String foodName;
  final String? foodImage;
  final String price;
  final String description;
  final List<String> sizes;

  const FoodDetailScreen({
    super.key,
    required this.foodName,
    this.foodImage,
    required this.price,
    required this.description,
    required this.sizes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = MerchantFoodDetailInput(
      foodName: foodName,
      price: price,
      sizes: sizes,
    );
    final detailState = ref.watch(merchantFoodDetailProvider(input));
    final detailNotifier = ref.read(merchantFoodDetailProvider(input).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: MerchantFoodDetailContent(
                foodName: foodName,
                foodImage: foodImage,
                displayPrice: price,
                description: description,
                sizes: detailState.sizes,
                selectedSize: detailState.selectedSize,
                onSelectSize: detailNotifier.selectSize,
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.spacing(context, 12),
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEDE7F2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7A6F88),
                            ),
                          ),
                          Text(
                            'PHP ${detailState.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 22),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF251A38),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      MerchantFoodDetailQuantityBar(
                        quantity: detailState.quantity,
                        onDecrease: detailNotifier.decrementQuantity,
                        onIncrease: detailNotifier.incrementQuantity,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 14)),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 20,
                      ),
                      label: const Text('Add to cart'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5F2D82),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              name: foodName,
                              size: detailState.selectedSize.label,
                              unitPrice: detailState.unitPrice,
                              quantity: detailState.quantity,
                            );

                        SnackBarUtils.showSuccess(
                          context,
                          '$foodName added to cart!',
                        );
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
          ],
        ),
      ),
    );
  }
}
