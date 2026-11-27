import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/provider/main/support/customer_service_chat_provider.dart';
import 'package:lesgo/presentation/widgets/support/customer_service_message_bubble.dart';

void main() {
  testWidgets('only Ibow replies offer speech playback', (tester) async {
    var taps = 0;
    Widget bubble(bool isUser) => CustomerServiceMessageBubble(
      message: CustomerServiceMessage(
        id: isUser ? 'user' : 'ibow',
        text: 'Hello',
        isUser: isUser,
        timestamp: DateTime(2020),
      ),
      onToggleSpeech: () => taps++,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Column(children: [bubble(true), bubble(false)])),
      ),
    );

    final play = find.byTooltip('Read Ibow reply aloud');
    expect(play, findsOneWidget);
    await tester.tap(play);
    expect(taps, 1);
  });
}
