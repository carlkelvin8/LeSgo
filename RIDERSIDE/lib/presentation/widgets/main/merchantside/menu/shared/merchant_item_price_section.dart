import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantItemPriceSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MerchantItemPriceSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Price (PHP)'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: context.acc(const Color(0xFF5F2D82)),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 12),
            vertical: ResponsiveUtils.spacing(context, 10),
          ),
          decoration: BoxDecoration(
            color: context.surf(Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.brd(Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Text(
                '₱',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: context.acc(const Color(0xFF5F2D82)),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // Digits with at most one dot and 2 decimals, so a pasted "12..5"
                  // or "abc" can't become the price.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                  ),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
