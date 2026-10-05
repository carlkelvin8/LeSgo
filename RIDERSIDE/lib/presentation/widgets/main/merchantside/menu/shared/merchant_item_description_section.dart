import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantItemDescriptionSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MerchantItemDescriptionSection({
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
          'Description',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 12),
            vertical: ResponsiveUtils.spacing(context, 10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Describe your item (e.g., ingredients, preparation style)',
            ),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
            ),
          ),
        ),
      ],
    );
  }
}
