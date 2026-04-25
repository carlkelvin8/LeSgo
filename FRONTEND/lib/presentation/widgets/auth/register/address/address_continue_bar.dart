import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';

class AddressContinueBar extends StatelessWidget {
  const AddressContinueBar({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.horizontalPadding(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(padding),
        child: PrimaryButton(
          text: 'Continue',
          onPressed: isLoading ? null : onPressed,
          backgroundColor: const Color(0xFF5F2D82),
          isLoading: isLoading,
        ),
      ),
    );
  }
}
