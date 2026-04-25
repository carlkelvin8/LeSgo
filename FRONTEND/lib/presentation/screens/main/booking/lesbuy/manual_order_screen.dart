import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../../../provider/main/profile/profile_provider.dart';
import '../../../../widgets/widgets.dart';

class ManualOrderScreen extends ConsumerWidget {
  final bool fromCart;

  const ManualOrderScreen({super.key, this.fromCart = false});

  // Direct checkout function for manual orders
  Future<void> _directCheckout(
    BuildContext context,
    WidgetRef ref,
    ManualOrderState manualOrderState,
  ) async {
    try {
      final orderDataSource = getIt<OrderRemoteDataSource>();
      final profileState = ref.read(profileProvider);
      final user = profileState.user;

      // Prepare order items from manual order
      final orderItems = manualOrderState.items.map((item) => OrderItemDto(
        name: item.name,
        quantity: item.quantity,
        estimatedPrice: 0.0, // Manual items don't have price
        notes: item.description,
      )).toList();

      final deliveryFee = 50.0;
      final total = deliveryFee; // Only delivery fee for manual orders

      final createOrderRequest = CreateOrderRequestDto(
        serviceId: 4, // LesBuy service ID
        estimatedDistanceM: 5000, // 5km default
        pickup: OrderAddressDto(
          address: 'Manual Order Pickup',
          lat: 8.4542, // Default Cagayan de Oro coordinates
          lng: 124.6319,
          contactName: 'LesBuy Store',
          contactPhone: '+639123456789',
        ),
        dropoff: OrderAddressDto(
          address: user?.addressLine1 ?? (profileState.address1.isNotEmpty 
              ? profileState.address1 
              : 'Brgy 6, Claveria, Cagayan'),
          lat: 8.4542,
          lng: 124.6319,
          contactName: user?.name ?? (profileState.name.isNotEmpty 
              ? profileState.name 
              : 'Customer'),
          contactPhone: user?.phone ?? '+639123456789',
        ),
        notes: 'Manual LesBuy order: ${orderItems.length} items',
        paymentMethod: 'cash',
        items: orderItems,
        meta: {
          'subtotal': 0.0,
          'delivery_fee': deliveryFee,
          'total': total,
          'order_type': 'lesbuy_manual',
        },
      );

      print('🔵 Manual LesBuy: Creating order with API...');
      final response = await orderDataSource.createOrder(createOrderRequest);
      print('🟢 Manual LesBuy: Order created successfully - ID: ${response.data.id}');

      if (context.mounted) {
        final orderId = response.data.id.toString();
        
        // Clear the manual order items
        ref.read(manualOrderProvider.notifier).clearAll();
        
        // Navigate to driver finding screen
        AppRouter.pushReplacement(
          context,
          BookingRoutes.driverFinding,
          arguments: {
            'orderId': orderId,
            'orderType': 'LesBuy Manual',
            'orderData': {
              'manualItems': manualOrderState.items.map((item) => {
                'name': item.name,
                'quantity': item.quantity,
                'description': item.description,
              }).toList(),
              'total': total,
              'deliveryFee': deliveryFee,
            },
          },
        );
      }
    } catch (e) {
      print('🔴 Manual LesBuy: Error creating order - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manualOrderState = ref.watch(manualOrderProvider);
    final manualOrderNotifier = ref.read(manualOrderProvider.notifier);
    final bool isEmpty = manualOrderState.items.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            BookingServiceHeader(
              title: 'Manual Order',
              action: const SizedBox.shrink(),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Info Section with Icon
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                      ),
                      padding: EdgeInsets.all(
                        ResponsiveUtils.spacing(context, 16),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5F2D82),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create your custom list',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      14,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5F2D82),
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveUtils.spacing(context, 4),
                                ),
                                Text(
                                  'Can\'t find what you need in the store? Add items manually below and our rider will find them for you.',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      12,
                                    ),
                                    color: const Color(0xFF5F2D82),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Add New Item Form
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                      ),
                      child: ManualOrderFormSection(
                        onAddItem: (name, description, quantity) {
                          manualOrderNotifier.addItem(
                            name,
                            description,
                            quantity,
                          );
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                    // Empty State or Items List
                    if (isEmpty) ...[
                      // Empty State
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.horizontalPadding(
                              context,
                            ),
                            vertical: ResponsiveUtils.spacing(context, 40),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Shopping bag icon
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 16),
                              ),
                              // "Your list is empty" heading
                              Text(
                                'Your list is empty',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    16,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 8),
                              ),
                              // Message
                              Text(
                                'Start adding items above to build\nyour custom order!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    13,
                                  ),
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Your List Section
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(
                            context,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your List (${manualOrderState.items.length} items)',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Clear All Items'),
                                    content: const Text(
                                      'Are you sure you want to remove all items from your list?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          manualOrderNotifier.clearAll();
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Clear all',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Clear all',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    14,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5F2D82),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                      // Items List
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(
                            context,
                          ),
                        ),
                        child: Column(
                          children: manualOrderState.items.map((item) {
                            return ManualOrderItemCard(
                              item: item,
                              onIncrement: () {
                                manualOrderNotifier.incrementQuantity(item.id);
                              },
                              onDecrement: () {
                                manualOrderNotifier.decrementQuantity(item.id);
                              },
                              onRemove: () {
                                manualOrderNotifier.removeItem(item.id);
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Confirm Button - Always visible
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price disclaimer
              Text(
                '📋 Prices are estimated. Final amount determined by rider.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 10),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              // Button Options
              Row(
                children: [
                  // Add to Cart Button (Outlined style)
                  Expanded(
                    child: SizedBox(
                      height: ResponsiveUtils.buttonHeight(context),
                      child: OutlinedButton(
                        onPressed: isEmpty
                            ? null
                            : () {
                                // Move items from "Your List" to confirmed checkout items
                                manualOrderNotifier.confirmItems();

                                SnackBarUtils.showSuccess(
                                  context,
                                  'Added ${manualOrderState.totalItems} items to checkout!',
                                );
                                if (fromCart) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    BookingRoutes.lesbuyCart,
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isEmpty
                                ? Colors.grey[300]!
                                : const Color(0xFF5F2D82),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: isEmpty
                                ? Colors.grey[600]
                                : const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  // Direct Checkout Button
                  Expanded(
                    child: PrimaryButton(
                      text: 'Checkout Now',
                      backgroundColor: isEmpty
                          ? Colors.grey[300]
                          : const Color(0xFF5F2D82),
                      onPressed: isEmpty
                          ? null
                          : () async {
                              // Direct checkout without going to cart
                              await _directCheckout(context, ref, manualOrderState);
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
