import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Custom date picker field that only accepts date format MM/DD/YYYY
class BirthdayField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String labelText;
  final Color focusedBorderColor;

  const BirthdayField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText = 'Birthday',
    this.focusedBorderColor = const Color(0xFF7C3AED),
  });

  @override
  State<BirthdayField> createState() => _BirthdayFieldState();
}

class _BirthdayFieldState extends State<BirthdayField> {
  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: widget.focusedBorderColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _selectBirthday,
      style: TextStyle(fontFamily: 'TT Fors', fontSize: ResponsiveUtils.fontSize(context, 16), color: AppColors.foreground(context, Colors.black87)),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(fontFamily: 'TT Fors', color: AppColors.foreground(context, Colors.grey[600]!), fontSize: ResponsiveUtils.fontSize(context, 14)),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: widget.focusedBorderColor,
          size: ResponsiveUtils.fontSize(context, 20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border(context, Colors.grey[300]!), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.focusedBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 16),
        ),
      ),
      validator: widget.validator,
    );
  }
}
