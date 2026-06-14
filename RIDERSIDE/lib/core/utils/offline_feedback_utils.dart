import 'package:flutter/material.dart';

import '../network/offline_exceptions.dart';
import '../services/api_service.dart';

bool isOfflineQueuedError(Object? error) {
  if (error is OfflineQueuedException) return true;
  if (error is Exception && error.toString().contains('OfflineQueuedException')) {
    return true;
  }
  final message = ApiService.extractError(error);
  return message.contains('will retry when connection returns') ||
      message.contains('Isusubok muli ang aksyon');
}

void showApiErrorSnackBar(
  BuildContext context,
  Object? error, {
  String? fallback,
}) {
  if (!context.mounted) return;

  final queued = isOfflineQueuedError(error);
  final message = queued
      ? 'Saved offline — will upload when connection returns.'
      : (fallback ?? ApiService.extractError(error));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: queued ? Colors.orange.shade800 : Colors.red.shade700,
      duration: const Duration(seconds: 5),
    ),
  );
}
