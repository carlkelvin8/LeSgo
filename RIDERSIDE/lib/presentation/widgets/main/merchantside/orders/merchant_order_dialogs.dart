import 'package:flutter/material.dart';

// Guard to prevent duplicate dialogs
final Set<String> _activeDialogs = {};

// Stateful dialog content to properly manage dropdown selection
class _CancelReasonDialogContent extends StatefulWidget {
  final String title;

  const _CancelReasonDialogContent({
    required this.title,
  });

  @override
  State<_CancelReasonDialogContent> createState() => _CancelReasonDialogContentState();
}

class _CancelReasonDialogContentState extends State<_CancelReasonDialogContent> {
  // Predefined rejection reasons
  static const List<String> _rejectionReasons = [
    'Out of stock',
    'Restaurant closed',
    'Too busy to fulfill order',
    'Item unavailable',
    'Incorrect order details',
    'Unable to contact customer',
    'Other reason',
  ];

  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select reason for rejection:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedReason,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Choose a reason'),
                ),
                items: _rejectionReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(reason),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedReason);
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
