import 'package:flutter/material.dart';

/// A reusable confirmation dialog.
///
/// Usage:
/// ```dart
/// showConfirmDialog(
///   context: context,
///   title: 'Logout',
///   message: 'Are you sure you want to logout?',
///   confirmLabel: 'Logout',
///   confirmColor: Color(0xFFE53935),
///   onConfirm: () { /* action */ },
/// );
/// ```
Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color confirmColor = const Color(0xFFE53935),
  required Future<void> Function() onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFF6B6B6B)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: Color(0xFF6B6B6B)),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await onConfirm();
          },
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: confirmColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
