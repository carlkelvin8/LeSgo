import 'package:flutter/material.dart';
import '../../../../global/dual_action_buttons.dart';

class MerchantFormActionButtonsSection extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onSubmit;
  final String submitLabel;
  final bool isSubmitting;

  const MerchantFormActionButtonsSection({
    super.key,
    required this.onDiscard,
    required this.onSubmit,
    this.submitLabel = 'Submit',
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return DualActionButtons(
      secondaryLabel: 'Discard',
      onSecondaryPressed: onDiscard,
      primaryLabel: submitLabel,
      onPrimaryPressed: onSubmit,
      isPrimaryLoading: isSubmitting,
    );
  }
}
