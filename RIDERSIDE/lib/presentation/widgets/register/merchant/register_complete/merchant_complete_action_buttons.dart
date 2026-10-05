import 'package:flutter/material.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../global/primary_button.dart';

class MerchantCompleteActionButtons extends StatelessWidget {
  final VoidCallback onProceed;

  const MerchantCompleteActionButtons({super.key, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
        PrimaryButton(text: 'Go to login', onPressed: onProceed),
        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
      ],
    );
  }
}
