import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class MerchantSpecialInstructionsBanner extends StatelessWidget {
  final String? orderInstructions;
  final List<String> itemInstructions;

  const MerchantSpecialInstructionsBanner({
    super.key,
    this.orderInstructions,
    this.itemInstructions = const [],
  });

  bool get hasContent {
    final orderText = orderInstructions?.trim();
    return (orderText != null && orderText.isNotEmpty) || itemInstructions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasContent) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_rounded,
                color: Colors.orange.shade800,
                size: ResponsiveUtils.fontSize(context, 20),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Special Instructions',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          if (orderInstructions != null && orderInstructions!.trim().isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            Text(
              orderInstructions!.trim(),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ],
          ...itemInstructions.map(
            (instruction) => Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
