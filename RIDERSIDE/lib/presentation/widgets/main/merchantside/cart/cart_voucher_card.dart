import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../core/utils/app_localization.dart';

class CartVoucherCard extends StatelessWidget {
  const CartVoucherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 14),
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: context.surf(Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.brd(const Color(0xFFE8E8E8))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, color: context.acc(Color(0xFF6B3A96))),
          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
          Expanded(
            child: Text(
              context.tr('Apply Voucher'),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                fontWeight: FontWeight.w600,
                color: context.acc(const Color(0xFF6B3A96)),
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.txt(Color(0xFF757575))),
        ],
      ),
    );
  }
}
