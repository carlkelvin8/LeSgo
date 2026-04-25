import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

/// Single OTP digit input box
class OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Color focusedBorderColor;

  const OtpInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.focusedBorderColor = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveUtils.spacing(context, 60);
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 24),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class OtpInputFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final Color focusedBorderColor;

  const OtpInputFields({
    super.key,
    required this.controllers,
    this.focusedBorderColor = const Color(0xFF7C3AED),
  });

  @override
  State<OtpInputFields> createState() => _OtpInputFieldsState();
}

class _OtpInputFieldsState extends State<OtpInputFields> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.controllers.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < widget.controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.controllers.length,
        (index) => OtpInputBox(
          controller: widget.controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) => _onOtpChanged(index, value),
          focusedBorderColor: widget.focusedBorderColor,
        ),
      ),
    );
  }
}
