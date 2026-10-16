import 'package:flutter/material.dart';
import '../wallet/wallet_light_painter.dart';

class RiderEarningsLightCard extends StatefulWidget {
  const RiderEarningsLightCard({super.key, required this.child});
  final Widget child;
  @override
  State<RiderEarningsLightCard> createState() => _RiderEarningsLightCardState();
}

class _RiderEarningsLightCardState extends State<RiderEarningsLightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.stop();
      _light.value = .35;
    } else if (!_light.isAnimating) {
      _light.repeat();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: WalletLightPainter(_light)),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFAA70E0).withValues(alpha: .35),
            ),
          ),
          child: widget.child,
        ),
      ],
    ),
  );
}
