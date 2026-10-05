import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/services/affiliate_launcher.dart';

void main() {
  test('installed app opens without a store redirect', () async {
    final launcher = AffiliateLauncher(openInstalled: () async => true,
        openUrl: (_) => throw StateError('Store must not open'));
    expect(await launcher.open(), isTrue);
  });
  test('missing app opens the verified package in Play Store', () async {
    final urls = <Uri>[];
    final launcher = AffiliateLauncher(openInstalled: () async => false,
        openUrl: (uri) async { urls.add(uri); return true; });
    expect(await launcher.open(), isTrue);
    expect(urls.single.toString(), 'market://details?id=com.lesgo.rider');
  });
  test('native and Play exceptions fall back to browser', () async {
    final urls = <Uri>[];
    final launcher = AffiliateLauncher(openInstalled: () async => throw Exception('native'),
        openUrl: (uri) async {
          urls.add(uri);
          if (uri.scheme == 'market') throw Exception('No Play Store');
          return true;
        });
    expect(await launcher.open(), isTrue);
    expect(urls.last.toString(), AffiliateLauncher.storeUrl);
  });
  test('all failures return false and a later attempt can retry', () async {
    var installed = false;
    final launcher = AffiliateLauncher(openInstalled: () async => installed,
        openUrl: (_) async => false);
    expect(await launcher.open(), isFalse);
    installed = true;
    expect(await launcher.open(), isTrue);
  });
  test('concurrent taps share the actual launch result', () async {
    final result = Completer<bool>();
    var calls = 0;
    final launcher = AffiliateLauncher(openInstalled: () { calls++; return result.future; },
        openUrl: (_) async => false);
    final first = launcher.open();
    final second = launcher.open();
    result.complete(false);
    expect(await first, isFalse);
    expect(await second, isFalse);
    expect(calls, 1);
  });
}
