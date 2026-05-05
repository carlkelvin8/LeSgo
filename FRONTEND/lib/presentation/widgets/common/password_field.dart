import 'package:flutter/material.dart';
import 'validated_text_field.dart';
import 'password_strength_indicator.dart';
import '../../../core/utils/validators.dart';

/// Specialized password field with show/hide toggle and strength indicator
class PasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final bool realTimeValidation;
  final bool enabled;
  final bool required;

  const PasswordField({
    super.key,
    this.label = 'Password',
    this.hint,
    required this.controller,
    this.validator,
    this.showStrengthIndicator = false,
    this.realTimeValidation = true,
    this.enabled = true,
    this.required = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValidatedTextField(
          label: widget.label,
          hint: widget.hint ?? 'Enter your password',
          controller: widget.controller,
          validator: widget.validator ?? Validators.password,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          realTimeValidation: widget.realTimeValidation,
          enabled: widget.enabled,
          required: widget.required,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            tooltip: _obscureText ? 'Show password' : 'Hide password',
          ),
        ),

        // Password strength indicator
        if (widget.showStrengthIndicator)
          PasswordStrengthIndicator(
            password: widget.controller.text,
          ),
      ],
    );
  }
}

/// Password confirmation field
class PasswordConfirmField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool realTimeValidation;
  final bool enabled;
  final bool required;

  const PasswordConfirmField({
    super.key,
    this.label = 'Confirm Password',
    this.hint,
    required this.controller,
    required this.passwordController,
    this.realTimeValidation = true,
    this.enabled = true,
    this.required = false,
  });

  @override
  State<PasswordConfirmField> createState() => _PasswordConfirmFieldState();
}

class _PasswordConfirmFieldState extends State<PasswordConfirmField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: widget.label,
      hint: widget.hint ?? 'Re-enter your password',
      controller: widget.controller,
      validator: (value) => Validators.confirmPassword(
        value,
        widget.passwordController.text,
      ),
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      realTimeValidation: widget.realTimeValidation,
      enabled: widget.enabled,
      required: widget.required,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.grey.shade600,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}
