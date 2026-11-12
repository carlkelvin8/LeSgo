import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantItemNameSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MerchantItemNameSection({
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
          context.tr('Item Name'),
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
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            onChanged: onChanged,
            maxLines: 1,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: context.tr('Enter item name (e.g., Margherita Pizza)'),
            ),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
            ),
          ),
        ),
      ],
    );
  }
}
