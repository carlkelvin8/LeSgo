import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/services/notification_payload.dart';

void main() {
  test('parse order payload', () {
    final payload = NotificationPayload.parse('order_42');
    expect(payload?.type, NotificationTargetType.order);
    expect(payload?.orderId, 42);
  });

  test('parse chat order payload', () {
    final payload = NotificationPayload.parse('chat_order_7');
    expect(payload?.type, NotificationTargetType.chatByOrder);
    expect(payload?.orderId, 7);
  });

  test('parse chat conversation payload', () {
    final payload = NotificationPayload.parse('chat_15');
    expect(payload?.type, NotificationTargetType.chatByConversation);
    expect(payload?.conversationId, 15);
  });

  test('fromRemoteData reads order_id and type', () {
    final payload = NotificationPayload.fromRemoteData({
      'order_id': '99',
      'type': 'order',
    });
    expect(payload?.type, NotificationTargetType.order);
    expect(payload?.orderId, 99);
  });

  test('fromRemoteData reads chat order_id', () {
    final payload = NotificationPayload.fromRemoteData({
      'order_id': '12',
      'type': 'chat',
    });
    expect(payload?.type, NotificationTargetType.chatByOrder);
    expect(payload?.orderId, 12);
  });
}
