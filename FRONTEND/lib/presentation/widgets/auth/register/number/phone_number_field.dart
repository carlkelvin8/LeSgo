import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Reusable phone number input field with +63 prefix protection
class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Color focusedBorderColor;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.hintText = '+63 XXX XXX XXXX',
    this.focusedBorderColor = const Color(0xFF5F2D82),
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_enforcePrefix);
  }

  void _enforcePrefix() {
    final text = widget.controller.text;
    if (!text.startsWith('+63 ')) {
      widget.controller.value = TextEditingValue(
        text: '+63 ',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_enforcePrefix);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
        LengthLimitingTextInputFormatter(17), // +63 + 10 digits + spaces
      ],
      style: TextStyle(
        fontSize: ResponsiveUtils.fontSize(context, 16),
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveUtils.fontSize(context, 16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.focusedBorderColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 12),
        ),
      ),
    );
  }
}
