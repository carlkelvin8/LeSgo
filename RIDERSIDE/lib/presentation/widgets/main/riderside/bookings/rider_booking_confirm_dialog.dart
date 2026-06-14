import 'package:flutter/material.dart';

Future<bool> showRiderBookingConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF5F2D82), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
