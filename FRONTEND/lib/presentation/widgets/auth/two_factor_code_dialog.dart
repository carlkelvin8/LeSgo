import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showTwoFactorCodeDialog(
  BuildContext context, {
  String title = 'Two-step verification',
  String message =
      'Enter the 6-digit code from Google Authenticator, or an 8-character backup code.',
}) async {
  final controller = TextEditingController();
  String? validationError;

  final code = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        icon: const Icon(
          Icons.security_outlined,
          color: Color(0xFF5F2D82),
          size: 36,
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(8),
              ],
              onSubmitted: (_) {
                final value = controller.text.trim();
                if (RegExp(r'^(?:\d{6}|[A-Za-z0-9]{8})$').hasMatch(value)) {
                  Navigator.pop(dialogContext, value);
                } else {
                  setState(() {
                    validationError =
                        'Enter a 6-digit code or 8-character backup code.';
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Authenticator code',
                hintText: '123456',
                errorText: validationError,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (RegExp(r'^(?:\d{6}|[A-Za-z0-9]{8})$').hasMatch(value)) {
                Navigator.pop(dialogContext, value);
              } else {
                setState(() {
                  validationError =
                      'Enter a 6-digit code or 8-character backup code.';
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
  return code;
}
