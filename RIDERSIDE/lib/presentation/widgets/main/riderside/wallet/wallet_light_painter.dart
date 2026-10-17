import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Repaints the decorative layer only; the balance and controls stay static.
class WalletLightPainter extends CustomPainter {
  WalletLightPainter(this.motion, {this.intensity = 1})
    : super(repaint: motion);
  final Animation<double> motion;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0520), Color(0xFF2A0D55), Color(0xFF5B2A90)],
        ).createShader(rect),
    );
    final shift = math.sin(motion.value * math.pi * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(.75 + shift * .2, -.35),
          radius: 1.15,
          colors: [
            const Color(0xFF9F62CD).withValues(alpha: .22 * intensity),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0xFFD5A5FA).withValues(alpha: .08);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 1.04, size.height * .08),
        size.width * (.25 + i * .12),
        ring,
      );
    }
    final beam = Rect.fromLTWH(
      -size.width * .6 + size.width * 2 * motion.value,
      -size.height,
      size.width * .4,
      size.height * 3,
    );
    canvas.save();
    canvas.rotate(-.22);
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .055 * intensity),
            Colors.transparent,
          ],
        ).createShader(beam),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WalletLightPainter oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.intensity != intensity;
}
