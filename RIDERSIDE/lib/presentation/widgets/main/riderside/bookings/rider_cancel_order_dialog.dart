import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/app_localization.dart';

Future<String?> showRiderCancelOrderDialog(BuildContext context) async {
  final lang = ProviderScope.containerOf(context).read(appLanguageProvider);
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 28),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Text(
              AppLocalization.translate('cancel_order', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.translate('please_provide_reason', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppLocalization.translate('reason_for_cancellation', lang),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            AppLocalization.translate('keep_order', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(dialogContext, reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: Text(
            AppLocalization.translate('cancel_order', lang),
            style: TextStyle(fontFamily: 'TT Fors'),
          ),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
