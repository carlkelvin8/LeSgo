import 'dart:math' as math;

import 'package:flutter/material.dart';

class IbowOrbitAvatar extends StatefulWidget {
  const IbowOrbitAvatar({
    super.key,
    required this.size,
    this.isThinking = false,
    this.onTap,
  });

  final double size;
  final bool isThinking;
  final VoidCallback? onTap;

  @override
  State<IbowOrbitAvatar> createState() => _IbowOrbitAvatarState();
}

class _IbowOrbitAvatarState extends State<IbowOrbitAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _reactController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isThinking ? 620 : 1800),
    )..repeat(reverse: true);
    _reactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant IbowOrbitAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isThinking != widget.isThinking) {
      _floatController.duration = Duration(
        milliseconds: widget.isThinking ? 620 : 1800,
      );
      _floatController
        ..stop()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _reactController.dispose();
    super.dispose();
  }

  void _react() {
    _reactController.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AnimatedBuilder(
      animation: Listenable.merge([_floatController, _reactController]),
      builder: (context, child) {
        final phase = _floatController.value * math.pi;
        final reaction = Curves.elasticOut.transform(_reactController.value);
        final bobHeight = widget.isThinking ? 3.5 : 2.0;
        final scale = 1 + math.sin(reaction * math.pi) * .13;

        return Transform.translate(
          offset: Offset(0, -math.sin(phase) * bobHeight),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE3F7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF8E4DC3,
                    ).withValues(alpha: widget.isThinking ? .3 : .16),
                    blurRadius: widget.isThinking ? 14 : 7,
                    spreadRadius: widget.isThinking ? 1 : 0,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/ai/ibow_orbit.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.smart_toy_rounded,
                  color: const Color(0xFF5F2D82),
                  size: widget.size * .56,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.onTap == null) return avatar;
    return Semantics(
      button: true,
      label: 'IBOW, tap to say hello',
      child: GestureDetector(
        onTap: _react,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      ),
    );
  }
}
