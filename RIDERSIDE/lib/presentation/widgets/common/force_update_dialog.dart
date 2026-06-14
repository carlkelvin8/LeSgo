import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_version_service.dart';

Future<void> showForceUpdateDialog(
  BuildContext context,
  AppVersionCheck check,
) async {
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Update required'),
        content: Text(
          check.message ??
              'A newer version of LezGo Rider is required to continue.',
        ),
        actions: [
          if (check.storeUrl != null)
            FilledButton(
              onPressed: () async {
                final uri = Uri.tryParse(check.storeUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update now'),
            ),
        ],
      ),
    ),
  );
}
