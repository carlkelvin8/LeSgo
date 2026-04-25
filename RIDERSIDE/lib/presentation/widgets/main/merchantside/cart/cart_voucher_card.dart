import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
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
          const Icon(Icons.local_offer_outlined, color: Color(0xFF6B3A96)),
          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
          Expanded(
            child: Text(
              'Apply Voucher',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B3A96),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF757575)),
        ],
      ),
    );
  }
}
