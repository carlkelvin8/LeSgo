import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/core/utils/date_display_utils.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/screens/main/profile_screen.dart';

class _Login implements LoginUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Logout implements LogoutUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  _Profile(String birthdate) {
    state = ProfileState(name: 'Test Customer', phone: '+639605114305', birthdate: birthdate);
  }

  @override
  Future<void> loadProfile() async {}

  @override
  Future<void> refreshProfile() async {}
}

void main() {
  group('formatDateOnly', () {
    test('drops the time from the API timestamp (the reported bug)', () {
      expect(formatDateOnly('2001-04-24T00:00:00.000000Z'), 'April 24, 2001');
    });

    test('handles the other shapes a date can arrive in', () {
      expect(formatDateOnly('2001-04-24'), 'April 24, 2001');
      expect(formatDateOnly('1999-12-05T00:00:00+08:00'), 'December 5, 1999');
      expect(formatDateOnly('1999-12-05 00:00:00'), 'December 5, 1999');
      expect(formatDateOnly('  2001-01-09T00:00:00Z  '), 'January 9, 2001');
    });

    test('never shifts the day, whatever the offset says', () {
      // A late-evening UTC instant must not become the next/previous day.
      expect(formatDateOnly('2001-04-24T23:59:59.000000Z'), 'April 24, 2001');
      expect(formatDateOnly('2001-04-24T00:00:00-12:00'), 'April 24, 2001');
    });

    test('accepts leap days and rejects impossible dates', () {
      expect(formatDateOnly('2000-02-29'), 'February 29, 2000');
      expect(formatDateOnly('2001-02-29'), '2001-02-29');
      expect(formatDateOnly('2001-13-01'), '2001-13-01');
      expect(formatDateOnly('2001-00-10'), '2001-00-10');
    });

    test('leaves empty and non-ISO text alone', () {
      expect(formatDateOnly(''), '');
      expect(formatDateOnly('April 24, 2001'), 'April 24, 2001');
      expect(formatDateOnly('24/04/2001'), '24/04/2001');
    });
  });

  testWidgets('the profile Birthday row shows a plain date, not the raw timestamp',
      (tester) async {
    tester.view.physicalSize = const Size(402, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((_) => _Profile('2001-04-24T00:00:00.000000Z')),
          authProvider.overrideWith((_) => AuthNotifier(_Login(), _Logout(), _Storage())),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('April 24, 2001'), findsOneWidget);
    expect(find.textContaining('T00:00'), findsNothing);
    expect(find.textContaining('000000Z'), findsNothing);
  });
}
