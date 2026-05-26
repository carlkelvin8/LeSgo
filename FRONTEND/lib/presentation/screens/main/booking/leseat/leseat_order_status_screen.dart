import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/order_contact_actions.dart';
import '../../../../../core/utils/order_status_mapper.dart';
import '../../../../widgets/review/rating_dialog.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../widgets/booking/leseat/checkout/delivery_address_section.dart';
import '../../../../widgets/booking/leseat/checkout/order_item_card.dart';
import '../../../../widgets/booking/leseat/checkout/order_summary_section.dart';
import '../../../../../domain/entities/booking/leseat/order_item.dart';

class LeseatOrderStatusScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderType;
  final Map<String, dynamic>? orderData;

  const LeseatOrderStatusScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.orderData,
  });

  @override
  ConsumerState<LeseatOrderStatusScreen> createState() => _LeseatOrderStatusScreenState();
}

class _LeseatOrderStatusScreenState extends ConsumerState<LeseatOrderStatusScreen> {
  String _currentStatus = 'cooking';
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  Timer? _statusPollTimer;
  Map<String, dynamic>? _liveOrderData;

  int get _orderIdInt => int.tryParse(widget.orderId) ?? 0;

  @override
  void initState() {
    super.initState();
    _liveOrderData = widget.orderData != null
        ? Map<String, dynamic>.from(widget.orderData!)
        : null;
    _currentStatus = OrderStatusMapper.toLesEatUiStatus(
      _liveOrderData?['status']?.toString(),
    );
    _fetchOrderStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchOrderStatus();
    });
  }

  Future<void> _fetchOrderStatus() async {
    if (_orderIdInt <= 0) return;
    try {
      final response =
          await getIt<OrderRemoteDataSource>().getOrder(_orderIdInt);
      if (!mounted || !response.success) return;

      final order = response.data;
      final meta = order.meta;
      final uiStatus = OrderStatusMapper.toLesEatUiStatus(order.status);

      setState(() {
        _currentStatus = uiStatus;
        _liveOrderData = {
          if (_liveOrderData != null) ..._liveOrderData!,
          'status': order.status,
          'restaurantName': _liveOrderData?['restaurantName'] ??
              meta?['restaurant_name'] ??
              order.pickupContactName,
          'deliveryAddress': order.dropoffAddress,
          'subtotal': meta?['subtotal'] ?? _liveOrderData?['subtotal'],
          'deliveryFee': order.effectiveDeliveryFee,
          'total': order.effectiveTotalAmount,
          'dropoff_lat': order.dropoffLat,
          'dropoff_lng': order.dropoffLng,
          'pickup_contact_phone': order.pickupContactPhone,
          'driver_id': order.driverId,
          'driver_name': order.driverProfile?.user?.name ??
              (order.driverId != null ? 'Driver #${order.driverId}' : null),
          'driver_phone': meta?['driver_phone']?.toString(),
        };
      });

      if (OrderStatusMapper.isTerminal(order.status)) {
        _statusPollTimer?.cancel();
      }
    } catch (e) {
      debugPrint('LesEat status poll failed: $e');
    }
  }

  Map<String, dynamic> get _orderData =>
      _liveOrderData ?? widget.orderData ?? {};

  String get _orderTypeKey =>
      OrderContactActions.normalizeOrderType(widget.orderType);

  void _contactRestaurant() {
    OrderContactActions.showContactOptions(
      context,
      orderId: _orderIdInt,
      orderType: _orderTypeKey,
      phone: OrderContactActions.phoneFromOrderData(_orderData),
    );
  }

  void _contactDriver() {
    OrderContactActions.showContactOptions(
      context,
      orderId: _orderIdInt,
      orderType: _orderTypeKey,
      phone: OrderContactActions.phoneFromOrderData(_orderData, driver: true),
      driverName: _orderData['driver_name']?.toString(),
      preferDriver: true,
    );
  }

  Future<void> _submitOrderReview() async {
    if (_orderIdInt <= 0) return;

    final result = await showRatingDialog(
      context: context,
      title: 'Rate Your Order',
      subtitle: 'How was your order?',
      reviewableType: 'order',
      reviewableId: _orderIdInt,
    );

    if (result != true || !mounted) return;

    final driverId = _orderData['driver_id'] as int?;
    if (driverId != null && driverId > 0) {
      await showRatingDialog(
        context: context,
        title: 'Rate Your Driver',
        subtitle: 'How was your delivery experience?',
        reviewableType: 'driver',
        reviewableId: driverId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/leseat_logo.png',
            height: ResponsiveUtils.spacing(context, 24),
            errorBuilder: (context, error, stackTrace) {
              return Text(
                'LesEat',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF6B35),
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.black87),
          onPressed: () {
            // TODO: Navigate to profile
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentStatus) {
      case 'cooking':
      case 'preparing':
        return _buildCookingView(context);
      case 'ready_for_pickup':
      case 'driver_assigned':
        return _buildReadyForDeliveryView(context);
      case 'on_the_way':
      case 'delivering':
        return _buildReadyForDeliveryView(context);
      case 'completed':
      case 'delivered':
        return _buildCompletedView(context);
      case 'cancelled':
        return _buildCookingView(context);
      default:
        return _buildCookingView(context);
    }
  }

  // View 1: Cooking Status
  Widget _buildCookingView(BuildContext context) {
    final orderData = _orderData;
    final restaurantName = orderData['restaurantName'] ?? 'Restaurant';
    final address = orderData['deliveryAddress'] ?? 'No address';
    final items = orderData['items'] as List<OrderItem>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      child: Column(
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 20)),

          // Illustration
          Container(
            width: ResponsiveUtils.spacing(context, 200),
            height: ResponsiveUtils.spacing(context, 200),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              size: ResponsiveUtils.fontSize(context, 80),
              color: Colors.orange[600],
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),

          // Status Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We are cooking your food!',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 18),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE53935),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        'Your order is being prepared',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
                if (true) // Loading indicator
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFE53935),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Address Section
          _buildSectionHeader(context, 'Address'),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(0xFF5F2D82),
                  size: ResponsiveUtils.fontSize(context, 24),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Your Order Section
          _buildSectionHeader(context, 'Your Order'),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ...items.map((item) => OrderItemCard(item: item)),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),

          // Contact Restaurant Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _contactRestaurant,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Contact Restaurant',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Ready for Delivery (with map)
  Widget _buildReadyForDeliveryView(BuildContext context) {
    final orderData = _orderData;
    final restaurantName = orderData['restaurantName'] ?? 'Restaurant';
    final address = orderData['deliveryAddress'] ?? 'No address';
    final items = orderData['items'] as List<OrderItem>? ?? [];

    return Column(
      children: [
        // Map Section
        Container(
          height: ResponsiveUtils.spacing(context, 300),
          color: Colors.grey[200],
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (orderData['dropoff_lat'] as num?)?.toDouble() ?? 8.4542,
                (orderData['dropoff_lng'] as num?)?.toDouble() ?? 124.6319,
              ),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            child: Column(
              children: [
                // Status Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'For Delivery!',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 18),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF57C00),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                            Text(
                              'Driver is on the way to pick up your order',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: const Color(0xFFF57C00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                // Address Section
                _buildSectionHeader(context, 'Address'),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: const Color(0xFF5F2D82),
                        size: ResponsiveUtils.fontSize(context, 24),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                // Your Order Section
                _buildSectionHeader(context, 'Your Order'),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                ...items.map((item) => OrderItemCard(item: item)),

                SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                // Contact Restaurant Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _contactRestaurant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F2D82),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Contact Restaurant',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                // Contact Driver Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _contactDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Contact Driver',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // View 3: Order Complete (with rating)
  Widget _buildCompletedView(BuildContext context) {
    final orderData = _orderData;
    final restaurantName = orderData['restaurantName'] ?? 'Restaurant';

    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      child: Column(
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 40)),

          // Restaurant Logo
          Container(
            width: ResponsiveUtils.spacing(context, 120),
            height: ResponsiveUtils.spacing(context, 120),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              size: ResponsiveUtils.fontSize(context, 60),
              color: Colors.orange[700],
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),

          // Restaurant Name
          Text(
            restaurantName,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 20),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Order Complete Message
          Text(
            'ORDER IS COMPLETE!',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F2D82),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),

          // Rating Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'How was the experience?',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 6),
                        ),
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: index < _rating
                              ? Colors.amber[600]
                              : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                // Review Text Field
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write your review here...',
                    hintStyle: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey[400],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5F2D82)),
                    ),
                    contentPadding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 16),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitOrderReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Book Another One Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AppRouter.pushReplacement(context, BookingRoutes.leseat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Book Another One',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 16),
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}
