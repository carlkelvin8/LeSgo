import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../global/primary_button.dart';

class LocationBottomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const LocationBottomButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(horizontalPadding),
        child: PrimaryButton(
          text: 'Continue',
          onPressed: onPressed,
          backgroundColor: const Color(0xFF5F2D82),
          isLoading: isLoading,
        ),
      ),
    );
  }
}
