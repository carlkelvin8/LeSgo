import 'package:flutter/material.dart';
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
      child: Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: onSave == null ? null : onCancel,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48),
            foregroundColor: const Color(0xFF5F2D82),
            side: const BorderSide(color: Color(0xFFDDD4E5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48),
            backgroundColor: const Color(0xFF5F2D82),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(onSave == null ? 'Saving...' : 'Save changes'))),
      ]),
    );
  }
}