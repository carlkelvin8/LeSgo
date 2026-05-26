import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/widgets/chat/order_chat_widget.dart';

/// Call / chat helpers for active orders (no UI changes — wire existing buttons).
class OrderContactActions {
  OrderContactActions._();

  /// Maps display labels (LesEat, lesgo, etc.) to chat API keys.
  static String normalizeOrderType(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('buy')) return 'lesbuy';
    if (t.contains('ride')) return 'lesride';
    if (t.contains('go')) return 'lesgo';
    if (t.contains('eat') || t.contains('seat')) return 'leseat';
    if (t == 'lesbuy' || t == 'lesride' || t == 'lesgo' || t == 'leseat') {
      return t;
    }
    return 'leseat';
  }

  static Future<void> callPhone(String? phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) return;
    final uri = Uri.parse('tel:$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static void openOrderChat(
    BuildContext context, {
    required int orderId,
    required String orderType,
    String? driverName,
  }) {
    if (orderId <= 0) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: orderId,
        orderType: normalizeOrderType(orderType),
        driverName: driverName,
      ),
    );
  }

  static String? phoneFromOrderData(Map<String, dynamic>? data, {bool driver = false}) {
    if (data == null) return null;
    if (driver) {
      return data['driver_phone']?.toString() ??
          data['driverPhone']?.toString() ??
          (data['driver'] is Map
              ? (data['driver'] as Map)['phone']?.toString()
              : null);
    }
    return data['pickup_contact_phone']?.toString() ??
        data['restaurant_phone']?.toString() ??
        data['pickupContactPhone']?.toString();
  }

  static String? _normalizePhone(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 7) return null;
    return digits;
  }

  /// Call and/or in-app chat from existing contact buttons.
  static void showContactOptions(
    BuildContext context, {
    required int orderId,
    required String orderType,
    String? phone,
    String? driverName,
    bool preferDriver = false,
  }) {
    if (orderId <= 0) return;

    final normalized = _normalizePhone(phone);
    final canCall = normalized != null;

    if (!canCall) {
      openOrderChat(
        context,
        orderId: orderId,
        orderType: orderType,
        driverName: driverName,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF5F2D82)),
              title: Text(preferDriver ? 'Call driver' : 'Call'),
              onTap: () {
                Navigator.pop(sheetContext);
                callPhone(normalized);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF5F2D82)),
              title: const Text('Message'),
              onTap: () {
                Navigator.pop(sheetContext);
                openOrderChat(
                  context,
                  orderId: orderId,
                  orderType: orderType,
                  driverName: driverName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
