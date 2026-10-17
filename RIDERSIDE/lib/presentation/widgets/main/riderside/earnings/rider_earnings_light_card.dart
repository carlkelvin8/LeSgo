import 'package:flutter/material.dart';
import '../wallet/wallet_light_painter.dart';

class RiderEarningsLightCard extends StatefulWidget {
  const RiderEarningsLightCard({
    super.key,
    required this.child,
    this.subtle = false,
  });
  final Widget child;
  final bool subtle;
  @override
  State<RiderEarningsLightCard> createState() => _RiderEarningsLightCardState();
}

class _RiderEarningsLightCardState extends State<RiderEarningsLightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.subtle || MediaQuery.disableAnimationsOf(context)) {
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
            child: widget.subtle
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF29143F), Color(0xFF683990)],
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: WalletLightPainter(_light, intensity: 1),
                  ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFAA70E0).withValues(alpha: .35),
            ),
          ),
          child: SizedBox(width: double.infinity, child: widget.child),
        ),
      ],
    ),
  );
}
