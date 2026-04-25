import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/booking/driver_finding_provider.dart';
import 'simple_order_tracking_screen.dart';

class DriverFindingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderType;
  final Map<String, dynamic>? orderData;

  const DriverFindingScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.orderData,
  });

  @override
  ConsumerState<DriverFindingScreen> createState() => _DriverFindingScreenState();
}

class _DriverFindingScreenState extends ConsumerState<DriverFindingScreen> {
  @override
  void initState() {
    super.initState();
    // Start finding driver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set context for notifications
      ref.read(driverFindingProvider.notifier).setContext(context);
      
      ref.read(driverFindingProvider.notifier).startFindingDriver(
        widget.orderId,
        widget.orderType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final findingState = ref.watch(driverFindingProvider);
    
    // Listen for driver found state and auto-navigate
    ref.listen<DriverFindingState>(driverFindingProvider, (previous, next) {
      if (next.driverFound && !next.isSearching && previous?.driverFound != true) {
        print('🎯 Driver found! Auto-navigating to tracking screen...');
        // Wait a moment to show the success message, then navigate
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToTracking();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (findingState.isSearching)
                        DriverFindingWidget(
                          orderId: widget.orderId,
                          orderType: widget.orderType,
                          onCancel: _handleCancelOrder,
                        )
                      else if (findingState.driverFound)
                        _buildDriverFoundWidget(context, findingState)
                      else if (findingState.error != null)
                        _buildErrorWidget(context, findingState.error!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleCancelOrder(),
            icon: const Icon(Icons.arrow_back),
            color: Colors.black87,
          ),
          Expanded(
            child: Text(
              'Order #${widget.orderId}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildDriverFoundWidget(BuildContext context, DriverFindingState state) {
    return Column(
      children: [
        // Success animation
        Container(
          width: ResponsiveUtils.spacing(context, 120),
          height: ResponsiveUtils.spacing(context, 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: ResponsiveUtils.fontSize(context, 60),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        
        Text(
          'Driver Found!',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 24),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        
        if (state.driverName != null)
          Text(
            state.driverName!,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5F2D82),
            ),
          ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        
        Text(
          'Your driver is on the way!',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        
        ElevatedButton(
          onPressed: () => _navigateToTracking(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 32),
              vertical: ResponsiveUtils.spacing(context, 16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Track Order',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: ResponsiveUtils.fontSize(context, 60),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        
        Text(
          'Unable to find driver',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        
        Text(
          error,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _retryFindingDriver(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleCancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(driverFindingProvider.notifier).cancelOrder(widget.orderId);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _retryFindingDriver() {
    ref.read(driverFindingProvider.notifier).startFindingDriver(
      widget.orderId,
      widget.orderType,
    );
  }

  void _navigateToTracking() {
    // Navigate to appropriate tracking screen based on order type
    if (widget.orderType.toLowerCase().contains('lesbuy')) {
      AppRouter.pushReplacement(
        context,
        BookingRoutes.lesbuyOrderTracking,
        arguments: {
          'orderId': widget.orderId,
          'orderType': widget.orderType,
          'orderData': widget.orderData,
        },
      );
    } else if (widget.orderType.toLowerCase().contains('leseat')) {
      AppRouter.pushReplacement(
        context,
        BookingRoutes.leseatOrderTracking,
        arguments: {
          'orderId': widget.orderId,
          'orderType': widget.orderType,
          'orderData': widget.orderData,
        },
      );
    } else {
      // Navigate to simple order tracking screen for other order types
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleOrderTrackingScreen(orderId: int.parse(widget.orderId)),
        ),
      );
    }
  }
}