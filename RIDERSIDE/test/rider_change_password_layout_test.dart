import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_change_password_screen.dart';

void main() {
  testWidgets(
    'Password form fits large text, toggles visibility and validates confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.7),
                viewInsets: const EdgeInsets.only(bottom: 240),
              ),
              child: child!,
            ),
            home: const RiderChangePasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(0));
      await tester.enterText(fields.at(0), 'current');
      await tester.ensureVisible(find.byTooltip('Show password').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .obscureText,
        isFalse,
      );
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), 'ValidNew123');
      await tester.ensureVisible(fields.at(2));
      await tester.enterText(fields.at(2), 'Different123');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
