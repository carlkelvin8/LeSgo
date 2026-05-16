import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class LeseatSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const LeseatSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.fontSize(context, 14);
    final borderRadius = ResponsiveUtils.spacing(context, 24);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: fontSize,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search for restaurants and groceries',
          hintStyle: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: fontSize,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFF5F2D82), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
            vertical: ResponsiveUtils.spacing(context, 10),
          ),
        ),
      ),
    );
  }
}
