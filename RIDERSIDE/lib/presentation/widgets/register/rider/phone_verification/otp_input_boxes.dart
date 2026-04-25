import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/utils.dart';

/// Single OTP digit input box
class OTPInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Color focusedBorderColor;

  const OTPInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.focusedBorderColor = const Color(0xFF5F2D82),
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveUtils.spacing(context, 70);
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 24),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class OTPInputBoxes extends StatefulWidget {
  final List<TextEditingController> controllers;
  final Color focusedBorderColor;

  const OTPInputBoxes({
    super.key,
    required this.controllers,
    this.focusedBorderColor = const Color(0xFF5F2D82),
  });

  @override
  State<OTPInputBoxes> createState() => _OTPInputBoxesState();
}

class _OTPInputBoxesState extends State<OTPInputBoxes> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        4,
        (index) => OTPInputBox(
          controller: widget.controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) => _onOtpChanged(index, value),
          focusedBorderColor: widget.focusedBorderColor,
        ),
      ),
    );
  }
}
