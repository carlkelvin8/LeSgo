import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced text field with real-time validation and better UX
/// Provides immediate feedback as user types
class ValidatedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool realTimeValidation;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLength;
  final int? maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool showLabel;
  final bool required;

  const ValidatedTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.realTimeValidation = true,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showLabel = true,
    this.required = false,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _errorText;
  bool _hasInteracted = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Add listener for real-time validation
    if (widget.realTimeValidation) {
      widget.controller.addListener(_validateRealTime);
    }

    // Add focus listener
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.realTimeValidation) {
      widget.controller.removeListener(_validateRealTime);
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// Validate in real-time as user types
  void _validateRealTime() {
    // Only validate after user has interacted with the field
    if (!_hasInteracted) return;

    setState(() {
      _errorText = widget.validator?.call(widget.controller.text);
    });
  }

  /// Get border color based on state
  Color _getBorderColor() {
    if (_errorText != null) return Colors.red;
    if (_isFocused) return const Color(0xFF5F2D82);
    return Colors.grey.shade300;
  }

  /// Get border width based on state
  double _getBorderWidth() {
    if (_errorText != null) return 1.5;
    if (_isFocused) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.showLabel) ...[
          Row(
            children: [
              Text(
                widget.label,
                style:  TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground(context, Colors.black87),
                  fontFamily: 'TT Fors',
                ),
              ),
              if (widget.required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontFamily: 'TT Fors',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'TT Fors',
          ),
          onChanged: (value) {
            // Mark as interacted on first change
            if (!_hasInteracted) {
              setState(() => _hasInteracted = true);
            }
            
            // Call external onChanged if provided
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.foreground(context, Colors.grey.shade400),
              fontSize: 14,
              fontFamily: 'TT Fors',
            ),
            errorText: _errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'TT Fors',
            ),
            errorMaxLines: 2,
            suffixIcon: widget.suffixIcon,
            prefixIcon: widget.prefixIcon,
            
            // Counter text (for maxLength)
            counterText: widget.maxLength != null ? '' : null,
            
            // Border styling
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: _getBorderWidth(),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: _getBorderWidth(),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.foreground(context, Colors.grey.shade200),
                width: 1,
              ),
            ),
            
            // Fill color
            filled: true,
            fillColor: widget.enabled
                ? (_isFocused ? AppColors.surface(context, Colors.white) : AppColors.surface(context, Colors.grey.shade50))
                : AppColors.surface(context, Colors.grey.shade100),
            
            // Padding
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: widget.validator,
        ),

        // Success indicator (when valid and has content)
        if (_hasInteracted &&
            _errorText == null &&
            widget.controller.text.isNotEmpty &&
            widget.validator != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Looks good!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'TT Fors',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
