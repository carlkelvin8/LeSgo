import 'package:flutter/material.dart';
import '../../../../global/dual_action_buttons.dart';
import '../../menu/shared/merchant_sticky_action_bar.dart';

class MerchantEditInformationActionBar extends StatelessWidget {
  const MerchantEditInformationActionBar({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return MerchantStickyActionBar(
      child: DualActionButtons(
        secondaryLabel: 'Cancel',
        onSecondaryPressed: onCancel,
        primaryLabel: 'Save Changes',
        onPrimaryPressed: onSave ?? () {},
      ),
    );
  }
}