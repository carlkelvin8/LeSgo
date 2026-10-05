import 'dart:async';
import 'package:lesgo/presentation/widgets/profile/profile_edit_section.dart';
import 'package:lesgo/presentation/provider/main/profile/controller/profile.controller.notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/data/data_source/dto/user/user_profile_dto.dart';
import 'package:lesgo/presentation/screens/main/profile_screen.dart';
import 'package:lesgo/presentation/widgets/common/retry_widget.dart';
import 'package:lesgo/presentation/widgets/common/refreshable_empty_state.dart';

class TestProfile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
  void show(ProfileState value) => state = value;
}

ProfileState loaded(String name) => ProfileState(
  name: name,
  email: 'hello@example.com',
  user: UserProfileDto(
    id: 1,
    name: name,
    email: 'hello@example.com',
    role: 'customer',
  ),
);

class PendingSave extends ProfileControllers {
  PendingSave() : super(name: 'Jane Doe');
  final done = Completer<void>();
  int calls = 0;
  @override
  Future<void> updateProfile(BuildContext context, WidgetRef ref) async {
    calls++;
    await done.future;
  }
}

void main() {
  testWidgets('late profile data fills fields and refresh preserves edits', (
    tester,
  ) async {
    final notifier = TestProfile();
    notifier.show(ProfileState(isLoading: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    notifier.show(loaded('Jane Doe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal details'));
    await tester.pumpAndSettle();
    final name = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(name).controller!.text, 'Jane Doe');
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Jane Edited');
    notifier.show(loaded('Jane Remote'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(name).controller!.text, 'Jane Edited');
    expect(tester.takeException(), isNull);
  });
  testWidgets('profile error retains back navigation', (tester) async {
    final notifier = TestProfile();
    notifier.show(ProfileState(error: 'Unable to load profile'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('retry fits constrained height and is disabled while loading', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 150,
            child: RetryWidget(
              message:
                  "type 'Null' is not a subtype of type 'String' in type cast",
              onRetry: () => retries++,
              isLoading: true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('subtype'), findsNothing);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    await tester.tap(find.text('Retrying…'), warnIfMissed: false);
    expect(retries, 0);
  });
  testWidgets('empty content can actually be pulled to refresh', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshableEmptyState(
            onRefresh: () async {
              refreshes++;
            },
            child: const Text('No orders'),
          ),
        ),
      ),
    );
    await tester.drag(find.text('No orders'), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });
  testWidgets('save validates input and prevents duplicate submissions', (
    tester,
  ) async {
    final notifier = TestProfile();
    final controllers = PendingSave();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileEditSection(controllers: controllers),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'A');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(controllers.calls, 0);
    expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Jane Doe');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    await tester.tap(find.text('Saving…'));
    expect(controllers.calls, 1);
    controllers.done.complete();
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controllers.dispose();
  });
}
