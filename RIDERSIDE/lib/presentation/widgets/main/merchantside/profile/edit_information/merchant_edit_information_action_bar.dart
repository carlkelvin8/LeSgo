import 'package:flutter/material.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../global/dual_action_buttons.dart';

class MerchantEditInformationActionBar extends StatelessWidget {
  const MerchantEditInformationActionBar({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 16),
        ResponsiveUtils.spacing(context, 8),
        ResponsiveUtils.spacing(context, 16),
        ResponsiveUtils.spacing(context, 10),
      ),
      child: SafeArea(
        top: false,
        child: DualActionButtons(
          secondaryLabel: 'Cancel',
          onSecondaryPressed: onCancel,
          primaryLabel: 'Save Changes',
          onPrimaryPressed: onSave,
        ),
      ),
    );
  }
}