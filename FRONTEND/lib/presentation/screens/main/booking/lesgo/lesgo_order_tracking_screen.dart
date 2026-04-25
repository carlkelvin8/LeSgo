import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../core/di/injection.dart';
import '../../../../provider/tracking/live_tracking_provider.dart';
import '../../../../provider/main/profile/profile_provider.dart';
import '../../../../widgets/tracking/order_status_timeline.dart';
import '../../../../widgets/tracking/driver_info_card.dart';
import '../../../../widgets/orders/cancel_order_dialog.dart';
import '../../../../widgets/chat/order_chat_widget.dart';
import '../../../../widgets/chat/chat_button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LesgoOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderType;
  final Map<String, dynamic>? orderData;

  const LesgoOrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.orderData,
  });

  @override
  ConsumerState<LesgoOrderTrackingScreen> createState() => _LesgoOrderTrackingScreenState();
}

class _LesgoOrderTrackingScreenState extends ConsumerState<LesgoOrderTrackingScreen> {
  GoogleMapController? _mapController;
  bool _isBottomSheetExpanded = false;
  bool _mapReady = false;
  bool _isCancelling = false;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set context for notifications
      ref.read(liveTrackingProvider(int.parse(widget.orderId)).notifier).setContext(context);
      _fitBounds();
    });
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = null;
    super.dispose();
  }

  void _startStatusPolling() {
    // Poll every 5 seconds for status updates
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        final trackingState = ref.read(liveTrackingProvider(int.parse(widget.orderId)));
        if (trackingState.isOrderActive) {
          ref.read(liveTrackingProvider(int.parse(widget.orderId)).notifier).refreshTracking();
        } else {
          // Stop polling if order is completed/cancelled
          _statusPollTimer?.cancel();
        }
      }
    });
  }

  void _fitBounds() {
    if (!_mapReady || _mapController == null) return;
    final bounds = ref
        .read(liveTrackingProvider(int.parse(widget.orderId)).notifier)
        .getCameraBounds();
    if (bounds != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } catch (_) {}
    }
  }

  void _callDriver() {
    final driverInfo = ref.read(liveTrackingProvider(int.parse(widget.orderId))).driverInfo;
    if (driverInfo?.phone != null) {
      launchUrl(Uri.parse('tel:${driverInfo!.phone}'));
    }
  }

  Future<void> _handleCancelOrder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => CancelOrderDialog(
        onConfirm: (reason) {
          Navigator.of(context).pop(reason);
        },
      ),
    );

    if (result != null && mounted) {
      setState(() => _isCancelling = true);

      try {
        final dataSource = getIt<OrderRemoteDataSource>();
        await dataSource.cancelOrder(int.parse(widget.orderId), result);

        if (mounted) {
          setState(() => _isCancelling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCancelling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _contactDriver() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: int.parse(widget.orderId),
        orderType: 'lesgo',
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Finding Driver';
      case 'accepted':
        return 'Driver Accepted';
      case 'driver_arrived':
        return 'Driver Arrived';
      case 'picked_up':
        return 'Package Picked Up';
      case 'in_transit':
        return 'On The Way';
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status.toUpperCase();
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Looking for available driver';
      case 'accepted':
        return 'Driver is on the way to pickup location';
      case 'driver_arrived':
        return 'Driver has arrived at pickup location';
      case 'picked_up':
        return 'Package has been picked up';
      case 'in_transit':
        return 'Package is being delivered';
      case 'completed':
        return 'Package has been delivered successfully';
      case 'cancelled':
        return 'Order has been cancelled';
      case 'failed':
        return 'Delivery failed';
      default:
        return 'Order status: $status';
    }
  }
  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider(int.parse(widget.orderId)));
    final orderData = widget.orderData ?? {};

    // Listen for tracking state changes to update map
    ref.listen<LiveTrackingState>(
      liveTrackingProvider(int.parse(widget.orderId)),
      (previous, next) {
        if (next.markers.isNotEmpty && _mapReady && previous?.markers != next.markers) {
          _fitBounds();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: trackingState.driverInfo != null
          ? FloatingChatButton(
              orderId: int.parse(widget.orderId),
              orderType: 'lesgo',
              driverName: trackingState.driverInfo?.name,
            )
          : null,
      body: Stack(
        children: [
          // Google Maps with real-time tracking
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: trackingState.pickupLocation ?? const LatLng(8.4542, 124.6319),
              zoom: 14,
            ),
            markers: trackingState.markers,
            polylines: trackingState.polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) {
              if (mounted) {
                _mapController = controller;
                _mapReady = true;
                // Fit bounds after a short delay to ensure markers are loaded
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _fitBounds();
                });
              }
            },
          ),

          // Loading overlay
          if (trackingState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                ),
              ),
            ),

          // Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 16)),

                    // Order Title
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 16),
                          vertical: ResponsiveUtils.spacing(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.orderType,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            right: ResponsiveUtils.spacing(context, 16),
            bottom: _isBottomSheetExpanded ? 400 : 280,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF5F2D82)),
                onPressed: _fitBounds,
              ),
            ),
          ),
          // Bottom Sheet with Order Details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  setState(() => _isBottomSheetExpanded = true);
                } else if (details.primaryDelta! > 5) {
                  setState(() => _isBottomSheetExpanded = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isBottomSheetExpanded ? 600 : 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: EdgeInsets.only(
                        top: ResponsiveUtils.spacing(context, 12),
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ETA Section (if available)
                            if (trackingState.eta != null) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Estimated Arrival',
                                            style: TextStyle(
                                              fontFamily: 'TT Fors',
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                          Text(
                                            trackingState.eta!,
                                            style: TextStyle(
                                              fontFamily: 'TT Fors',
                                              color: Colors.white,
                                              fontSize: ResponsiveUtils.fontSize(context, 24),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (trackingState.distance != null)
                                            Text(
                                              trackingState.distance!,
                                              style: const TextStyle(
                                                fontFamily: 'TT Fors',
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (trackingState.isLoadingRoute)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                            ],
                            // Delivery Status Banner
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFE69C)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5F2D82),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getStatusText(trackingState.orderStatus),
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 16),
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                        Text(
                                          _getStatusDescription(trackingState.orderStatus),
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 12),
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Pickup and Dropoff Addresses Section
                            _buildAddressSection(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Package Details Section
                            _buildPackageDetailsSection(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Order Summary
                            _buildOrderSummary(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Driver Info
                            if (trackingState.driverInfo != null)
                              DriverInfoCard(
                                driverInfo: trackingState.driverInfo!,
                                onCall: _callDriver,
                                onChat: _contactDriver,
                              ),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Contact Driver Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _contactDriver,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  padding: EdgeInsets.symmetric(
                                    vertical: ResponsiveUtils.spacing(context, 14),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Contact Driver',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // Cancel Order Button (if applicable)
                            if (trackingState.orderStatus == 'pending' ||
                                trackingState.orderStatus == 'accepted') ...[
                              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isCancelling ? null : _handleCancelOrder,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    side: BorderSide(color: Colors.red[700]!),
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.spacing(context, 14),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isCancelling
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          'Cancel Order',
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 16),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],

                            // Order Timeline (when expanded)
                            if (_isBottomSheetExpanded) ...[
                              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                              const Divider(),
                              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                              if (trackingState.tracking != null)
                                OrderStatusTimeline(
                                  tracking: trackingState.tracking!,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAddressSection(BuildContext context, Map<String, dynamic> orderData) {
    final pickupAddress = orderData['pickupAddress'] ?? 'Pickup location';
    final dropoffAddress = orderData['dropoffAddress'] ?? 'Dropoff location';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Addresses',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),

        // Pickup Address
        Container(
          margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.green[700],
                  size: 20,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      pickupAddress,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dropoff Address
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag,
                  color: Colors.red[700],
                  size: 20,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dropoff Location',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      dropoffAddress,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageDetailsSection(BuildContext context, Map<String, dynamic> orderData) {
    final itemLocation = orderData['itemLocation'] ?? 'Not specified';
    final itemWeight = orderData['itemWeight'] ?? 'Not specified';
    final notes = orderData['notes'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package Details',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),

        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Item Location
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Location',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          itemLocation,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              // Item Weight
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.scale,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Weight',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          itemWeight,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notes (if available)
              if (notes.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.note,
                        color: Colors.purple[700],
                        size: 16,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            notes,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildOrderSummary(BuildContext context, Map<String, dynamic> orderData) {
    final baseFee = orderData['baseFee'] ?? 0.0;
    final distanceFee = orderData['distanceFee'] ?? 0.0;
    final total = orderData['total'] ?? 0.0;
    final paymentMethod = orderData['paymentMethod'] ?? 'Cash';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow(context, 'Base Fee', 'Php ${baseFee.toStringAsFixed(2)}'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildSummaryRow(context, 'Distance Fee', 'Php ${distanceFee.toStringAsFixed(2)}'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Divider(color: Colors.grey[300]),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildSummaryRow(
                context, 
                'Total', 
                'Php ${total.toStringAsFixed(2)}',
                isTotal: true,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Divider(color: Colors.grey[300]),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildSummaryRow(context, 'Payment Method', paymentMethod),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 16 : 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 16 : 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? const Color(0xFF5F2D82) : Colors.black87,
          ),
        ),
      ],
    );
  }
}