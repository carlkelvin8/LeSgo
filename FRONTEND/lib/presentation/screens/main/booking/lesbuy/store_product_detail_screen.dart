import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/product.dart';
import '../../../../provider/main/booking/lesbuy/store_product_detail_provider.dart';
import '../../../../provider/main/booking/lesbuy/store_detail_provider.dart';
import '../../../../widgets/booking/lesbuy/store_product_detail/store_product_detail_image_section.dart';
import '../../../../widgets/booking/lesbuy/store_product_detail/store_product_quantity_selector.dart';
import '../../../../widgets/booking/lesbuy/store_product_detail/store_product_add_to_order_button.dart';

class StoreProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const StoreProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends ConsumerState<StoreProductDetailScreen> {
  // Use a unique provider family instance if needed, or better yet, auto-dispose the provider
  // Since storeProductDetailProvider is family, we use the product instance.

  void _handleAddToOrder() {
    final detailState = ref.read(storeProductDetailProvider(widget.product));
    final storeNotifier = ref.read(storeDetailProvider.notifier);

    // Add item to cart with selected quantity
    for (int i = 0; i < detailState.quantity; i++) {
        storeNotifier.addToCart(widget.product);
    }

    // Show success message
    SnackBarUtils.showInfo(
      context,
      '${detailState.quantity} ${widget.product.name} added to cart',
    );

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(storeProductDetailProvider(widget.product));
    final detailNotifier = ref.read(
      storeProductDetailProvider(widget.product).notifier,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Image Section (Top 55-60%)
          Expanded(
            flex: 6,
            child: StoreProductDetailImageSection(product: widget.product),
          ),

          // Details Section (Bottom 40-45%)
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    ResponsiveUtils.spacing(context, 24),
                  ),
                  topRight: Radius.circular(
                    ResponsiveUtils.spacing(context, 24),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fixed header - Title, Price
                  Padding(
                    padding: EdgeInsets.only(
                      left: ResponsiveUtils.horizontalPadding(context),
                      right: ResponsiveUtils.horizontalPadding(context),
                      top: ResponsiveUtils.spacing(context, 20),
                      bottom: ResponsiveUtils.spacing(context, 8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 24),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        // Price
                        Text(
                          '₱${widget.product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 20),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5F2D82),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content - Description
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          // Description
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[700],
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom section - Quantity Selector and Add to Order Button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.horizontalPadding(context),
                      vertical: ResponsiveUtils.spacing(context, 16),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          // Quantity Selector
                          Flexible(
                            fit: FlexFit.loose,
                            child: StoreProductQuantitySelector(
                              quantity: detailState.quantity,
                              onIncrement: () =>
                                  detailNotifier.incrementQuantity(),
                              onDecrement: () =>
                                  detailNotifier.decrementQuantity(),
                            ),
                          ),

                          SizedBox(width: ResponsiveUtils.spacing(context, 12)),

                          // Add to Order Button
                          Expanded(
                            flex: 2,
                            child: StoreProductAddToOrderButton(
                              totalPrice: detailState.totalPrice,
                              onPressed: _handleAddToOrder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
