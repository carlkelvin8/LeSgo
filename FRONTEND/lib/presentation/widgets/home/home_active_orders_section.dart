import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/order_service_labels.dart';
import '../../../core/utils/order_status_mapper.dart';
import '../../../core/utils/order_tracking_navigation.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/data_source/dto/order/order_dto.dart';
import '../../provider/main/orders/active_orders_provider.dart';

class HomeActiveOrdersSection extends ConsumerStatefulWidget {
  const HomeActiveOrdersSection({super.key});

  @override
  ConsumerState<HomeActiveOrdersSection> createState() =>
      _HomeActiveOrdersSectionState();
}

class _HomeActiveOrdersSectionState extends ConsumerState<HomeActiveOrdersSection> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // Faster
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate( // BIGGER pulse
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(activeOrdersProvider.notifier).loadActiveOrders();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeOrdersProvider);
    final order = state.primaryOrder;

    if (state.isLoading && order == null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.horizontalPadding(context),
        ),
        child:  LinearProgressIndicator(
          color: Color(0xFF5F2D82),
          backgroundColor: AppColors.surface(context, Color(0xFFE8D5F2)),
        ),
      );
    }

    if (order == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActiveOrderCard(
            order: order,
            extraCount: state.extraCount,
            pulseAnimation: _pulseAnimation,
            onTrack: () => OrderTrackingNavigation.openTracking(context, order),
            onViewAll: state.extraCount > 0
                ? () => AppRouter.push(context, MainRoutes.transactions)
                : null,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatefulWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.extraCount,
    required this.pulseAnimation,
    required this.onTrack,
    this.onViewAll,
  });

  final OrderDto order;
  final int extraCount;
  final Animation<double> pulseAnimation;
  final VoidCallback onTrack;
  final VoidCallback? onViewAll;

  @override
  State<_ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<_ActiveOrderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final serviceLabel = OrderServiceLabels.labelForOrder(widget.order);
    final statusLabel = OrderStatusMapper.toDisplayLabel(widget.order.status);
    final destination = widget.order.dropoffAddress.isNotEmpty
        ? widget.order.dropoffAddress
        : widget.order.pickupAddress;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTrack();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(14),
          color: AppColors.accent(context, Color(0xFF5F2D82)),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: widget.pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track your order',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 15),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$serviceLabel • #${widget.order.id} • $statusLabel',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (destination.isNotEmpty && !destination.startsWith('Instance of ')) ...[
                        const SizedBox(height: 2),
                        Text(
                          destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      if (widget.extraCount > 0) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: widget.onViewAll,
                          child: Text(
                            '+${widget.extraCount} more active order${widget.extraCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
