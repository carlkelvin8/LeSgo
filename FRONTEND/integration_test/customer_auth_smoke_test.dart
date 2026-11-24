import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lesgo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('customer auth screens show expected states', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Login page: expected title and required-field validation.
    expect(find.text('Welcome Back!'), findsOneWidget);
    final editableFields = find.byType(EditableText);
    expect(editableFields, findsNWidgets(2));
    expect(
      tester.widget<EditableText>(editableFields.first).autocorrect,
      isFalse,
    );

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Email or phone number is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Email entry must preserve the exact text, with no iOS autocorrection.
    final emailField = find.byType(TextFormField).first;
    const qaEmail = 'qa.customer.20261112.7c4e9f@example.com';
    await tester.enterText(emailField, qaEmail);
    await tester.pump();
    expect(tester.widget<TextFormField>(emailField).controller?.text, qaEmail);

    // Password recovery: empty submission remains local and shows validation.
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email to receive an OTP code'), findsOneWidget);
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Signup: show terms, then decline. Never submit or accept terms in production.
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Terms and Conditions'), findsWidgets);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
