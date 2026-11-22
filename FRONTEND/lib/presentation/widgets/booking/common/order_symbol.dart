import 'package:flutter/material.dart';

/// Draws the service-specific marks on a shared 24-point grid.
class OrderSymbol extends StatelessWidget {
  const OrderSymbol(
    this.icon, {
    super.key,
    required this.color,
    this.size = 22,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = switch (icon) {
      Icons.my_location_rounded => _Mark.pickup,
      Icons.location_on_outlined => _Mark.pin,
      Icons.electric_rickshaw => _Mark.tricycle,
      Icons.inventory_2_outlined => _Mark.parcel,
      Icons.money || Icons.local_atm_outlined => _Mark.cash,
      Icons.account_balance_wallet ||
      Icons.account_balance_wallet_outlined => _Mark.wallet,
      Icons.phone_android || Icons.credit_card_rounded => _Mark.digital,
      Icons.local_shipping_outlined => _Mark.truck,
      _ => null,
    };
    if (mark == null) return Icon(icon, size: size, color: color);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _OrderMark(mark, color)),
    );
  }
}

enum _Mark { pickup, pin, tricycle, parcel, cash, wallet, digital, truck }

class _OrderMark extends CustomPainter {
  const _OrderMark(this.mark, this.color);

  final _Mark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: .17);

    void line(double x, double y, double x2, double y2) =>
        canvas.drawLine(Offset(x, y), Offset(x2, y2), stroke);
    void circle(double x, double y, double radius) =>
        canvas.drawCircle(Offset(x, y), radius, stroke);
    void rounded(double x, double y, double w, double h, double r) {
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      );
      canvas.drawRRect(box, fill);
      canvas.drawRRect(box, stroke);
    }

    switch (mark) {
      case _Mark.pickup:
        circle(12, 12, 6.5);
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        circle(12, 12, 2.4);
        line(12, 3, 12, 5.5);
        line(12, 18.5, 12, 21);
        line(3, 12, 5.5, 12);
        line(18.5, 12, 21, 12);
      case _Mark.pin:
        final path = Path()
          ..moveTo(12, 21)
          ..cubicTo(9, 18, 5, 14, 5, 10)
          ..cubicTo(5, 6, 8, 3, 12, 3)
          ..cubicTo(16, 3, 19, 6, 19, 10)
          ..cubicTo(19, 14, 15, 18, 12, 21)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        circle(12, 10, 2.3);
      case _Mark.tricycle:
        final canopy = Path()
          ..moveTo(3, 15)
          ..lineTo(4, 7)
          ..quadraticBezierTo(4.3, 5.5, 6, 5.5)
          ..lineTo(12, 5.5)
          ..quadraticBezierTo(13.5, 5.5, 14, 7)
          ..lineTo(18, 13)
          ..lineTo(20, 13)
          ..quadraticBezierTo(21, 13, 21, 15)
          ..lineTo(21, 16)
          ..lineTo(3, 16)
          ..close();
        canvas.drawPath(canopy, fill);
        canvas.drawPath(canopy, stroke);
        line(10, 6, 10, 12);
        line(5, 12, 16, 12);
        line(14, 12, 14, 16);
        circle(6, 18.2, 2.1);
        circle(18, 18.2, 2.1);
      case _Mark.parcel:
        rounded(4, 5, 16, 15, 2);
        line(4, 9, 20, 9);
        line(10, 5, 10, 13);
        line(14, 5, 14, 13);
        line(10, 13, 14, 13);
      case _Mark.cash:
        rounded(3, 6, 18, 12, 2.5);
        circle(12, 12, 2.4);
        line(6, 12, 7, 12);
        line(17, 12, 18, 12);
      case _Mark.wallet:
        rounded(3.5, 6, 17, 13.5, 2.5);
        line(6, 6, 17, 4);
        rounded(14, 10, 7, 5, 1.5);
        canvas.drawCircle(
          const Offset(16.5, 12.5),
          .8,
          stroke..style = PaintingStyle.fill,
        );
      case _Mark.digital:
        rounded(3, 6, 18, 12, 2.5);
        line(3, 10, 21, 10);
        line(6, 14.5, 10.5, 14.5);
        line(16, 14.5, 18, 14.5);
      case _Mark.truck:
        rounded(3, 5.5, 11.5, 11, 2);
        final cab = Path()
          ..moveTo(14.5, 9)
          ..lineTo(18, 9)
          ..lineTo(21.5, 13)
          ..lineTo(21.5, 16.5)
          ..lineTo(14.5, 16.5);
        canvas.drawPath(cab, stroke);
        line(15, 13, 21, 13);
        circle(7, 18.5, 2);
        circle(18, 18.5, 2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrderMark oldDelegate) =>
      mark != oldDelegate.mark || color != oldDelegate.color;
}
