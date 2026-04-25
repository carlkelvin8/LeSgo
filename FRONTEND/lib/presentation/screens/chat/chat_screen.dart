import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/chat/chat_provider.dart';
import '../../widgets/chat/order_chat_widget.dart';

/// Standalone chat screen - wraps OrderChatWidget in a full screen
class ChatScreen extends ConsumerWidget {
  final int orderId;
  final String orderType;

  const ChatScreen({
    super.key,
    required this.orderId,
    this.orderType = 'lesgo',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Order #$orderId'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: OrderChatWidget(
        orderId: orderId,
        orderType: orderType,
        showHeader: false,
        height: double.infinity,
      ),
    );
  }
}
