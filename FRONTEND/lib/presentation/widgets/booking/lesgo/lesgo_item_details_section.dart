import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Item details section for LesGo delivery service.
/// Contains fields for item location description and weight.
class LesgoItemDetailsSection extends StatelessWidget {
  const LesgoItemDetailsSection({
    super.key,
    required this.itemLocationController,
    required this.itemWeightController,
    this.onItemLocationChanged,
    this.onItemWeightChanged,
  });

  final TextEditingController itemLocationController;
  final TextEditingController itemWeightController;
  final ValueChanged<String>? onItemLocationChanged;
  final ValueChanged<String>? onItemWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Details',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        
        // Item Location Field
        _LesgoItemTextField(
          controller: itemLocationController,
          labelText: 'What are the items?',
          hintText: 'e.g., Books, Clothes, Electronics etc.',
          prefixIcon: Icons.location_on_outlined,
          onChanged: onItemLocationChanged,
          maxLines: 2,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        
        // Item Weight Field
        _LesgoItemTextField(
          controller: itemWeightController,
          labelText: 'Estimated Weight',
          hintText: 'e.g., 5 kg',
          prefixIcon: Icons.scale_outlined,
          onChanged: onItemWeightChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          suffixText: 'kg',
        ),
      ],
    );
  }
}

/// Custom text field styled for LesGo item details
class _LesgoItemTextField extends StatelessWidget {
  const _LesgoItemTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.suffixText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.fontSize(context, 14);
    final padding = ResponsiveUtils.spacing(context, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w500,
            color: AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.grey[50]!),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.foreground(context, Colors.grey[300]!),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: fontSize,
              color: AppColors.foreground(context, Colors.black87),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: fontSize,
                color: AppColors.foreground(context, Colors.grey[400]!),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding * 0.5,
                ),
                child: Icon(
                  prefixIcon,
                  size: ResponsiveUtils.spacing(context, 20),
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: ResponsiveUtils.spacing(context, 44),
              ),
              suffixText: suffixText,
              suffixStyle: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground(context, Colors.grey[600]!),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
