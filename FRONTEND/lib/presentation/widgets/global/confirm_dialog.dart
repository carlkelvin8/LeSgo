import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';

Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color confirmColor = const Color(0xFFE53935),
  required FutureOr<void> Function() onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.foreground(ctx, const Color(0xFF1A1A1A)),
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: AppColors.foreground(ctx, const Color(0xFF6B6B6B)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            cancelLabel,
            style: TextStyle(
              color: AppColors.foreground(ctx, const Color(0xFF6B6B6B)),
            ),
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
