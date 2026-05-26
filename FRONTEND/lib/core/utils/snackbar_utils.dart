import 'package:flutter/material.dart';

import 'api_error_mapper.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  /// Shows a user-friendly message; never displays raw Dio/technical errors.
  static void showErrorFrom(
    BuildContext context,
    Object? error, {
    String? fallbackEn,
    String? fallbackTl,
  }) {
    showError(
      context,
      ApiErrorMapper.message(
        error,
        fallbackEn: fallbackEn,
        fallbackTl: fallbackTl,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    final safe = ApiErrorMapper.message(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(safe),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF5F2D82),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}
