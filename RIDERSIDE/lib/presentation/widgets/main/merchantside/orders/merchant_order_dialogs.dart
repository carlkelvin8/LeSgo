import 'package:flutter/material.dart';

// Guard to prevent duplicate dialogs
final Set<String> _activeDialogs = {};

Future<String?> showMerchantCancelReasonDialog(
  BuildContext context, {
  required String title,
  String hint = 'Reason for cancellation',
}) async {
  // Create unique dialog ID
  final dialogId = 'cancel_reason_${context.hashCode}';
  
  // Prevent duplicate dialogs
  if (_activeDialogs.contains(dialogId)) {
    debugPrint('⚠️ Merchant cancel dialog already showing, ignoring duplicate call');
    return null;
  }
  
  _activeDialogs.add(dialogId);
  
  try {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Must tap button to close
      builder: (dialogContext) => AlertDialog(
        key: ValueKey(dialogId), // Unique key per dialog
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  } finally {
    _activeDialogs.remove(dialogId);
  }
}

Future<bool> showMerchantConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  // Create unique dialog ID
  final dialogId = 'confirm_${context.hashCode}_${title.hashCode}';
  
  // Prevent duplicate dialogs
  if (_activeDialogs.contains(dialogId)) {
    debugPrint('⚠️ Merchant confirm dialog already showing, ignoring duplicate call');
    return false;
  }
  
  _activeDialogs.add(dialogId);
  
  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Must tap button to close
      builder: (dialogContext) => AlertDialog(
        key: ValueKey(dialogId), // Unique key per dialog
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  } finally {
    _activeDialogs.remove(dialogId);
  }
}
