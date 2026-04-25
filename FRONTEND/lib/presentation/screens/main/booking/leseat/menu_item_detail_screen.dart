import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../../provider/main/booking/menu_item_detail_provider.dart';
import '../../../../provider/main/booking/restaurant_detail_provider.dart';

class MenuItemDetailScreen extends ConsumerStatefulWidget {
  final MenuItem menuItem;

  const MenuItemDetailScreen({super.key, required this.menuItem});

  @override
  ConsumerState<MenuItemDetailScreen> createState() =>
      _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends ConsumerState<MenuItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider with the menu item
    Future.microtask(() {
      ref.read(menuItemDetailProvider(widget.menuItem));
    });
  }

  void _handleAddToOrder() {
    final detailState = ref.read(menuItemDetailProvider(widget.menuItem));
    final restaurantNotifier = ref.read(restaurantDetailProvider.notifier);

    // Add item to cart with selected quantity
    for (int i = 0; i < detailState.quantity; i++) {
      restaurantNotifier.addToCart(widget.menuItem);
    }

    // Show success message
    SnackBarUtils.showInfo(
      context,
      '${detailState.quantity} ${widget.menuItem.name} added to cart',
    );

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(menuItemDetailProvider(widget.menuItem));
    final detailNotifier = ref.read(
      menuItemDetailProvider(widget.menuItem).notifier,
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
            child: MenuItemDetailImageSection(menuItem: widget.menuItem),
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
                children: [
                  // Fixed header - Title, Price, and Delivery Time
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
                          widget.menuItem.name,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 24),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        // Price and Delivery Time
                        Row(
                          children: [
                            Text(
                              '₱${detailState.adjustedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 20),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5F2D82),
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Icon(
                              Icons.access_time,
                              size: ResponsiveUtils.fontSize(context, 16),
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                            Text(
                              '20-30 min',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content - Description and Size Options
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
                            widget.menuItem.description,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[700],
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                          ),

                          SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                          // Size Selection - only show if item has size options
                          if (widget.menuItem.hasSizeOptions) ...[
                            MenuItemSizeSelector(
                              sizeOptions: widget.menuItem.sizeOptions!,
                              selectedSize: detailState.selectedSize,
                              onSizeSelected: (String size) {
                                detailNotifier.selectSize(size);
                              },
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                          ],
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
                            child: MenuItemQuantitySelector(
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
                            child: MenuItemAddToOrderButton(
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
