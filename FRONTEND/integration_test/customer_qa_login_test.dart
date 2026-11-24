import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lesgo/main.dart' as app;
import 'package:lesgo/presentation/screens/main/home_screen.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/screens/auth/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QA customer reaches the signed-in app', (tester) async {
    const email = String.fromEnvironment('QA_EMAIL');
    const password = String.fromEnvironment('QA_PASSWORD');
    expect(email, isNotEmpty, reason: 'Provide QA_EMAIL through Dart defines.');
    expect(password, isNotEmpty,
        reason: 'Provide QA_PASSWORD through Dart defines.');

    await app.main();
    var loginSent = false;
    int? loginStatus;
    String? loginMessage;
    final dio = getIt<DioClient>().dio;
    final observer = InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.endsWith('/auth/login')) {
          loginSent = true;
          final data = options.data as Map;
          expect(data['email'] == email && data['password'] == password, isTrue,
              reason: 'The UI must submit the supplied QA credentials exactly.');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.requestOptions.path.endsWith('/auth/login')) {
          loginStatus = response.statusCode;
          final data = response.data;
          if (data is Map) loginMessage = data['message']?.toString();
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.requestOptions.path.endsWith('/auth/login')) {
          loginStatus = error.response?.statusCode;
          final data = error.response?.data;
          loginMessage = data is Map
              ? data['message']?.toString() ?? data['title']?.toString()
              : error.type.name;
        }
        handler.next(error);
      },
    );
    dio.interceptors.insert(0, observer);
    addTearDown(() => dio.interceptors.remove(observer));
    for (var i = 0; i < 100 && find.text('Welcome Back!').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Welcome Back!'), findsOneWidget);
    String? authError;
    var authStarted = false;
    final auth = ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    ).read(authProvider.notifier);
    final removeAuthListener = auth.addListener((state) {
      if (state.isLoading) authStarted = true;
      if (state.error != null) authError = state.error;
    });
    addTearDown(removeAuthListener);
    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(2));
    // Keep the native iOS IME from overwriting injected test text. The actual
    // form, validation, network request, and route navigation remain real.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.pump();
    expect(tester.widget<EditableText>(fields.at(0)).controller.text == email,
        isTrue, reason: 'QA email input did not persist.');
    expect(tester.widget<EditableText>(fields.at(1)).controller.text == password,
        isTrue, reason: 'QA password input did not persist.');
    // Hide the software keyboard before tapping the login action.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Log In'));
    // Scrolling and keyboard dismissal change the button position. Finish
    // layout before hit-testing the real button.
    await tester.pump(const Duration(seconds: 1));
    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
    expect(loginButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(loginButton).onPressed, isNotNull);
    await tester.tap(loginButton);
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (authError != null) {
        fail('QA login failed: request sent=$loginSent, HTTP=$loginStatus, '
            'app error=$authError');
      }
      if (loginStatus != null && loginStatus! >= 400) {
        fail('QA login HTTP $loginStatus: $loginMessage');
      }
      if (find.text('The provided credentials are incorrect.').evaluate().isNotEmpty) {
        fail('Production API rejected the QA credentials entered by the test.');
      }
      if (find.byType(HomeScreen).evaluate().isNotEmpty) {
        // Allow the signed-in route to render before asserting navigation.
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Welcome Back!'), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        return;
      }
    }
    final visibleText = tester.widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((text) => !text.contains(email) && !text.contains(password))
        .join(' | ');
    fail('Login timed out: auth started=$authStarted, request sent=$loginSent, HTTP=$loginStatus, '
        'message=$loginMessage. Visible page: $visibleText');
  });
}
