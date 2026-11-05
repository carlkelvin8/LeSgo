import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_prep_timer_provider.dart';

MerchantPrepTimerEntry _startedAgo(Duration elapsed) => MerchantPrepTimerEntry(
      orderId: 1,
      startedAt: DateTime.now().subtract(elapsed),
      durationMinutes: 15,
    );

void main() {
  test('a timer under an hour keeps its clock', () {
    expect(_startedAgo(const Duration(minutes: 5)).displayLabel, matches(r'^09:\d\d$'));
    expect(_startedAgo(const Duration(minutes: 20)).displayLabel, matches(r'^-0[45]:\d\d$'));
  });

  test('a timer overdue by hours reads in hours, not thousands of minutes', () {
    final label = _startedAgo(const Duration(hours: 18, minutes: 30)).displayLabel;

    expect(label, matches(r'^-18h \d\dm$'));
  });
}
