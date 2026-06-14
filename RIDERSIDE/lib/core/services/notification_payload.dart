/// Parsed deep-link target from a push/local notification payload.
enum NotificationTargetType {
  order,
  chatByOrder,
  chatByConversation,
  merchantOrders,
  inbox,
  unknown,
}

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.orderId,
    this.conversationId,
  });

  final NotificationTargetType type;
  final int? orderId;
  final int? conversationId;

  static NotificationPayload? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    final chatOrder = RegExp(r'^chat_order_(\d+)$').firstMatch(value);
    if (chatOrder != null) {
      return NotificationPayload(
        type: NotificationTargetType.chatByOrder,
        orderId: int.parse(chatOrder.group(1)!),
      );
    }

    final order = RegExp(r'^order_(\d+)$').firstMatch(value);
    if (order != null) {
      return NotificationPayload(
        type: NotificationTargetType.order,
        orderId: int.parse(order.group(1)!),
      );
    }

    final chat = RegExp(r'^chat_(\d+)$').firstMatch(value);
    if (chat != null) {
      return NotificationPayload(
        type: NotificationTargetType.chatByConversation,
        conversationId: int.parse(chat.group(1)!),
      );
    }

    if (value == 'merchant_order') {
      return const NotificationPayload(type: NotificationTargetType.merchantOrders);
    }

    if (value == 'inbox') {
      return const NotificationPayload(type: NotificationTargetType.inbox);
    }

    return const NotificationPayload(type: NotificationTargetType.unknown);
  }

  static NotificationPayload? fromRemoteData(Map<String, dynamic> data) {
    final explicit = data['payload']?.toString();
    if (explicit != null && explicit.isNotEmpty) {
      return parse(explicit);
    }

    final orderId = data['order_id']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      final type = data['type']?.toString().toLowerCase();
      if (type == 'chat' || type == 'message') {
        return NotificationPayload(
          type: NotificationTargetType.chatByOrder,
          orderId: int.tryParse(orderId),
        );
      }
      return NotificationPayload(
        type: NotificationTargetType.order,
        orderId: int.tryParse(orderId),
      );
    }

    final conversationId = data['conversation_id']?.toString();
    if (conversationId != null && conversationId.isNotEmpty) {
      return NotificationPayload(
        type: NotificationTargetType.chatByConversation,
        conversationId: int.tryParse(conversationId),
      );
    }

    return null;
  }
}
