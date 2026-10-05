import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Verified Google Play listing: LeSgo Affiliates (LESGO COURIER SERVICES).
class AffiliateLauncher {
  static const packageId = 'com.lesgo.rider';
  static const storeUrl = 'https://play.google.com/store/apps/details?id=$packageId';
  static const _channel = MethodChannel('com.lesgo.app/affiliate');

  AffiliateLauncher({Future<bool> Function()? openInstalled,
    Future<bool> Function(Uri)? openUrl})
      : _openInstalled = openInstalled ?? (() async =>
            await _channel.invokeMethod<bool>('openAffiliate') ?? false),
        _openUrl = openUrl ?? ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final Future<bool> Function() _openInstalled;
  final Future<bool> Function(Uri) _openUrl;
  Future<bool>? _pending;

  Future<bool> open() => _pending ??= _launch().whenComplete(() => _pending = null);

  Future<bool> _launch() async {
      try { if (await _openInstalled()) return true; } catch (_) {}
      for (final uri in [Uri.parse('market://details?id=$packageId'), Uri.parse(storeUrl)]) {
        try { if (await _openUrl(uri)) return true; } catch (_) {}
      }
      return false;

  }
}
