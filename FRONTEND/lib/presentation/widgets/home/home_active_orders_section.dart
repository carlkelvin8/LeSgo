import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/order_progress.dart';
import '../../../core/utils/order_service_labels.dart';
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

class _HomeActiveOrdersSectionState
    extends ConsumerState<HomeActiveOrdersSection>
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      // BIGGER pulse
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
          horizontal: ResponsiveUtils.spacing(context, 16),
        ),
        child: LinearProgressIndicator(
          color: Color(0xFF5F2D82),
          backgroundColor: AppColors.surface(context, Color(0xFFE8D5F2)),
        ),
      );
    }

    if (order == null) return const SizedBox.shrink();

    // Same 16 pt side margin as the hero banner below, with a gap so the two
    // cards no longer touch.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 16),
        0,
        ResponsiveUtils.spacing(context, 16),
        ResponsiveUtils.spacing(context, 12),
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

class _ActiveOrderCardState extends State<_ActiveOrderCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  // A soft light that sweeps across the card every few seconds so it reads
  // as "live" without glowing or pulsing.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _sheenStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sheenStarted) return;
    _sheenStarted = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  static IconData _serviceIcon(String service) {
    switch (service) {
      case 'LesRide':
      case 'LesTransport':
        return Icons.two_wheeler_rounded;
      case 'LesEat':
        return Icons.restaurant_rounded;
      case 'LesBuy':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final service = OrderServiceLabels.labelForOrder(order);
    final progress = OrderProgress.of(
      service: service,
      status: order.status,
      scheduledAt: order.scheduledAt,
    );
    final extra = widget.extraCount;

    return Semantics(
      button: true,
      label: '${progress.headline}. $service order. Opens tracking.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTrack();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 14),
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    // White text sits on top, so keep the brand purple in dark mode too.
                    color: const Color(0xFF5F2D82),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5F2D82).withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          // Service icon; a small "+N" badge when more orders are active.
                          SizedBox(
                            width: 46,
                            height: 44,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _serviceIcon(service),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                if (extra > 0)
                                  Positioned(
                                    right: 0,
                                    top: -2,
                                    child: GestureDetector(
                                      onTap: widget.onViewAll,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '+$extra',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF5F2D82),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.headline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      15,
                                    ),
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$service order',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      12,
                                    ),
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 10)),
                      _ProgressBar(
                        progress: progress,
                        pulse: widget.pulseAnimation,
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sheen,
                      builder: (context, _) =>
                          CustomPaint(painter: _SheenPainter(_sheen.value)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin four-segment bar: finished steps are solid and the current one
/// breathes. No labels; the headline above already says what is happening.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.pulse});

  final OrderProgress progress;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget bar(Color color) => Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
    return Semantics(
      label:
          'Step ${progress.stepIndex + 1} of ${progress.stepLabels.length}: ${progress.stepLabels[progress.stepIndex]}',
      child: Row(
        children: [
          for (var i = 0; i < progress.stepLabels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: i == progress.stepIndex && !reduceMotion
                  ? AnimatedBuilder(
                      animation: pulse,
                      builder: (context, _) {
                        // pulse runs 1.0..1.12; map to a soft 0.55..1.0 glow.
                        final glow = 0.55 + ((pulse.value - 1) / 0.12) * 0.45;
                        return bar(Colors.white.withValues(alpha: glow));
                      },
                    )
                  : bar(
                      i <= progress.stepIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A narrow diagonal band of soft white light moving left to right, then
/// resting for the rest of the cycle.
class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep during the first 38% of the cycle, then rest.
    const sweep = 0.38;
    if (t > sweep) return;
    final p = Curves.easeInOut.transform(t / sweep);
    final bandWidth = size.width * 0.35;
    final x = -bandWidth + (size.width + bandWidth * 2) * p;
    final rect = Rect.fromLTWH(x, 0, bandWidth, size.height);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(0.35);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(
      rect.inflate(size.height * 0.3),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) => old.t != t;
}
