import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_profile_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_edit_profile_screen.dart';

class _Profile extends RiderProfileNotifier {
  _Profile(super.ref) {
    state = const RiderProfileState(
      name: 'Carl',
      contact: '09949768791',
      plateNumber: '1234554321',
      referralCode: '7F39F831',
    );
  }
  @override
  Future<void> loadProfile({bool silent = false}) async {}
}

void main() {
  for (final large in [false, true]) {
    testWidgets('Edit profile supports keyboard and large text: $large', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'app_language': large ? 'tl' : 'en',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderProfileProvider.overrideWith((ref) => _Profile(ref)),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness: large ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(large ? 2 : 1),
                viewInsets: const EdgeInsets.only(bottom: 280),
              ),
              child: child!,
            ),
            home: const RiderEditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
      final nameField = find.byType(TextFormField).first;
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, '');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(
        find.text(large ? 'Kinakailangan ang pangalan' : 'Name is required'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(SelectableText));
      await tester.pumpAndSettle();
      expect(find.text('7F39F831'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

