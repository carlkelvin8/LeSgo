import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/widgets/common/validated_text_field.dart';
import 'package:lesgo/presentation/widgets/global/custom_text_field.dart';

void main() {
  testWidgets('email input preserves text without autocorrect or suggestions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValidatedTextField(
            label: 'Email/Phone',
            hint: 'Enter your email or phone number',
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.autocorrect, isFalse);
    expect(editable.enableSuggestions, isFalse);

    const email = 'qa.customer.20261112.7c4e9f@example.com';
    await tester.enterText(find.byType(TextFormField), email);
    await tester.pump();
    expect(controller.text, email);
  });

  testWidgets('custom email input also disables autocorrect', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.autocorrect, isFalse);
    expect(editable.enableSuggestions, isFalse);
  });

  testWidgets('validating a valid field clears the submitted error', (
    tester,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: ValidatedTextField(
              label: 'Email/Phone',
              controller: controller,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Email is required' : null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'qa.customer@example.com',
    );
    await tester.pump();

    expect(find.text('Email is required'), findsNothing);
    expect(find.text('Looks good!'), findsOneWidget);
  });
}
