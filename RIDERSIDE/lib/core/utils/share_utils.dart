import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ShareUtils {
  static Future<void> shareText(BuildContext context, String text, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: '',
      queryParameters: {
        'subject': subject,
        'body': text,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _fallbackCopy(context, text);
    }
  }

  static Future<void> saveAndShareReceipt(BuildContext context, String content, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename.txt');
      await file.writeAsString(content);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved: ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: '',
                  queryParameters: {
                    'subject': filename,
                    'body': content,
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  _fallbackCopy(context, content);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _fallbackCopy(context, content);
      }
    }
  }

  static void _fallbackCopy(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt content is ready. Please copy it manually.')),
    );
  }
}
