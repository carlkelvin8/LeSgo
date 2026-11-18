import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/order_payment_label.dart';

OrderPaymentLabel l(String s, String p, [String m = 'cash']) =>
    orderPaymentLabel(status: s, paymentStatus: p, paymentMethod: m);

void main() {
  test('cancelled + failed/pending/unpaid reads Not charged, neutral', () {
    for (final p in ['failed', 'pending', 'unpaid', 'cash']) {
      final r = l('cancelled', p);
      expect(r.text, 'Not charged');
      expect(r.tone, OrderPaymentTone.neutral);
    }
    expect(l('canceled', 'failed').text, 'Not charged');
    expect(l('Cancelled', 'FAILED').text, 'Not charged');
  });

  test('refunded and paid are kept, even when cancelled', () {
    expect(l('cancelled', 'refunded', 'wallet').text, 'REFUNDED');
    expect(l('cancelled', 'paid', 'paymongo').text, 'PAID');
    expect(l('completed', 'paid').tone, OrderPaymentTone.success);
    expect(l('completed', 'paid').color(Colors.grey), Colors.green);
  });

  test('non-cancelled behaviour unchanged', () {
    final r = l('pending', 'failed');
    expect(r.text, 'FAILED');
    expect(r.color(Colors.grey), Colors.orange);
    expect(l('in_progress', 'pending').text, 'PENDING');
  });

  test('neutral tone uses supplied colour', () {
    expect(l('cancelled', 'failed').color(Colors.grey), Colors.grey);
  });
}
