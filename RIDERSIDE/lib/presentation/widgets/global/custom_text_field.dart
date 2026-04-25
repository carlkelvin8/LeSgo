import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 12),
            ),
            border: Border.all(
              color: _errorMessage != null ? Colors.red : Colors.grey.shade300,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
            vertical: ResponsiveUtils.spacing(context, 4),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            validator: (value) {
              final error = widget.validator?.call(value);
              // Use post-frame to avoid setState during build
              Future.microtask(() {
                if (mounted && _errorMessage != error) {
                  setState(() {
                    _errorMessage = error;
                  });
                }
              });
              return error;
            },
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey.shade500,
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: ResponsiveUtils.imageHeight(context, 20),
                      ),
                    )
                  : widget.suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 12),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Padding(
            padding: EdgeInsets.only(left: ResponsiveUtils.spacing(context, 4)),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors
                    .red
                    .shade900, // Darker red for text to match design usually, or just red
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
