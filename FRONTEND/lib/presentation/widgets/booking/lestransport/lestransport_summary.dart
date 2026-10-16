import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/booking/lestransport_provider.dart';

class LestransportSummary extends ConsumerWidget {
  const LestransportSummary({super.key});

  String _formatPrice(double price) {
    return 'PHP ${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lestransportProvider);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context, Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          
          // Shipping Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Fee',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              Text(
                _formatPrice(state.shippingFee),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          
          // Standard Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Standard Delivery',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              Text(
                _formatPrice(state.standardDeliveryFee),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          
          // Dotted divider
          CustomPaint(
            painter: DottedLinePainter(),
            size: const Size(double.infinity, 1),
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          
          // Total Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Order',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              Text(
                _formatPrice(state.totalOrder),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
