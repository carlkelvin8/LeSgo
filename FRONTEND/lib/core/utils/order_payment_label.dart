import 'package:flutter/material.dart';

enum OrderPaymentTone { success, neutral, warning }

class OrderPaymentLabel {
  final String text;
  final OrderPaymentTone tone;
  const OrderPaymentLabel(this.text, this.tone);

  /// Colour for [tone]; [neutral] is supplied by the caller (theme aware).
  Color color(Color neutral) {
    switch (tone) {
      case OrderPaymentTone.success:
        return Colors.green;
      case OrderPaymentTone.warning:
        return Colors.orange;
      case OrderPaymentTone.neutral:
        return neutral;
    }
  }
}

/// Customer-facing payment label for an order.
///
/// A cancelled order whose payment was never taken (cash/unpaid/pending/
/// failed) reads "Not charged" instead of an alarming "FAILED". Non-cancelled
/// orders keep the raw status upper-cased (orange unless paid).
OrderPaymentLabel orderPaymentLabel({
  required String status,
  required String paymentStatus,
  String? paymentMethod,
}) {
  final s = status.trim().toLowerCase();
  final p = paymentStatus.trim().toLowerCase();
  final cancelled = s == 'cancelled' || s == 'canceled';

  if (p == 'refunded' || p == 'refund') {
    return const OrderPaymentLabel('REFUNDED', OrderPaymentTone.neutral);
  }
  if (p == 'paid') {
    return const OrderPaymentLabel('PAID', OrderPaymentTone.success);
  }
  if (cancelled) {
    return const OrderPaymentLabel('Not charged', OrderPaymentTone.neutral);
  }
  return OrderPaymentLabel(
    paymentStatus.toUpperCase(),
    OrderPaymentTone.warning,
  );
}
