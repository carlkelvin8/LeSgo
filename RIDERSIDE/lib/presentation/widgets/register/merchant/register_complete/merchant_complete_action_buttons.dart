import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../global/primary_button.dart';

class MerchantCompleteActionButtons extends StatelessWidget {
  final VoidCallback onProceed;

  const MerchantCompleteActionButtons({super.key, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: ResponsiveUtils.spacing(context, 40),
        ), // Spacer from previous content
        // Proceed to payment button
        PrimaryButton(text: 'Proceed to payment', onPressed: onProceed),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Via Gcash with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Via Gcash',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            SvgPicture.asset(
              'assets/images/Gcash.svg',
              height: ResponsiveUtils.imageHeight(context, 24),
            ),
          ],
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
      ],
    );
  }
}
