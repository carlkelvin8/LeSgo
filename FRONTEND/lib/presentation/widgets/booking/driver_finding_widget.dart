import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';

/// Clean, reusable driver finding widget
class DriverFindingWidget extends ConsumerWidget {
  final String orderId;
  final String orderType; // 'LesEat', 'LesBuy', 'LesRide'
  final VoidCallback? onCancel;
  final VoidCallback? onDriverFound;

  const DriverFindingWidget({
    super.key,
    required this.orderId,
    required this.orderType,
    this.onCancel,
    this.onDriverFound,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimation(context),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _buildTitle(context),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _buildSubtitle(context),
          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          _buildEstimatedTime(context),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          if (onCancel != null) _buildCancelButton(context),
        ],
      ),
    );
  }

  Widget _buildAnimation(BuildContext context) {
    return Container(
      width: ResponsiveUtils.spacing(context, 120),
      height: ResponsiveUtils.spacing(context, 120),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing circle
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            width: ResponsiveUtils.spacing(context, 100),
            height: ResponsiveUtils.spacing(context, 100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          // Inner icon
          Container(
            width: ResponsiveUtils.spacing(context, 60),
            height: ResponsiveUtils.spacing(context, 60),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF5F2D82),
            ),
            child: Icon(
              _getOrderIcon(),
              color: Colors.white,
              size: ResponsiveUtils.fontSize(context, 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Finding your driver...',
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 20),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'We\'re looking for the best driver near you for your $orderType order.',
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 14),
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEstimatedTime(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.orange,
            size: ResponsiveUtils.fontSize(context, 16),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Estimated wait: 2-5 minutes',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: onCancel,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 24),
          vertical: ResponsiveUtils.spacing(context, 12),
        ),
      ),
      child: Text(
        'Cancel Order',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  IconData _getOrderIcon() {
    switch (orderType.toLowerCase()) {
      case 'leseat':
        return Icons.restaurant;
      case 'lesbuy':
        return Icons.shopping_bag;
      case 'lesride':
        return Icons.directions_car;
      default:
        return Icons.delivery_dining;
    }
  }
}
