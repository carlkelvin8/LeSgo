import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/widgets/support/ibow_orbit_avatar.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('animates, reacts to a tap and survives mood changes', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(IbowOrbitAvatar(size: 150, onTap: () => taps++)),
    );
    // Idle: blink, wander and float without throwing.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(IbowOrbitAvatar));
    expect(taps, 1);
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Thinking then speaking.
    await tester.pumpWidget(
      _host(const IbowOrbitAvatar(size: 150, isThinking: true)),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(
      _host(const IbowOrbitAvatar(size: 150, isSpeaking: true)),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('eyes track a touch elsewhere on screen', (tester) async {
    await tester.pumpWidget(_host(const IbowOrbitAvatar(size: 120)));
    await tester.pump(const Duration(milliseconds: 200));
    final gesture = await tester.startGesture(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('still mode and reduce-motion run no ticker', (tester) async {
    await tester.pumpWidget(
      _host(const IbowOrbitAvatar(size: 32, animated: false)),
    );
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _host(const IbowOrbitAvatar(size: 120), disableAnimations: true),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
