import 'package:flutter/material.dart';

// Guard to prevent duplicate dialogs
final Set<String> _activeDialogs = {};

// Stateful dialog content to properly manage TextEditingController lifecycle
class _CancelReasonDialogContent extends StatefulWidget {
  final String title;
  final String hint;

  const _CancelReasonDialogContent({
    required this.title,
    required this.hint,
  });

  @override
  State<_CancelReasonDialogContent> createState() => _CancelReasonDialogContentState();
}

class _CancelReasonDialogContentState extends State<_CancelReasonDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: widget.hint),
        maxLines: 2,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.of(context).pop(reason);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

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
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Must tap button to close
      builder: (dialogContext) => _CancelReasonDialogContent(
        title: title,
        hint: hint,
      ),
    );
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
