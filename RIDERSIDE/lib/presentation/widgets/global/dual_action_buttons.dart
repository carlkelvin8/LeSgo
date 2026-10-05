import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'primary_button.dart';

class DualActionButtons extends StatelessWidget {
  const DualActionButtons({
    super.key,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.isPrimaryLoading = false,
  });

  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.spacing(context, 52);
    final labelFontSize = ResponsiveUtils.fontSize(context, 14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: isPrimaryLoading ? null : onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 8),
                ),
                side: const BorderSide(color: Color(0xFF5F2D82), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  secondaryLabel,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        Expanded(
          child: PrimaryButton(
            text: primaryLabel,
            onPressed: isPrimaryLoading ? null : onPrimaryPressed,
            isLoading: isPrimaryLoading,
            fontSize: labelFontSize,
            fitText: true,
          ),
        ),
      ],
    );
  }
}