import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/chat/rider_chat_screen.dart';

class RiderChatButton extends ConsumerWidget {
  final int orderId;
  final String? customerName;

  const RiderChatButton({
    super.key,
    required this.orderId,
    this.customerName,
  });

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderChatScreen(
          orderId: orderId,
          customerName: customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  customerName != null
                      ? 'Chat with $customerName'
                      : 'Chat with Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button version for booking detail screens
class FloatingRiderChatButton extends ConsumerWidget {
  final int orderId;
  final String? customerName;

  const FloatingRiderChatButton({
    super.key,
    required this.orderId,
    this.customerName,
  });

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderChatScreen(
          orderId: orderId,
          customerName: customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      heroTag: 'chat_fab_$orderId',
      onPressed: () => _openChat(context),
      backgroundColor: const Color(0xFF5F2D82),
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    );
  }
}
