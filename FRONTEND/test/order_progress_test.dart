import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/order_progress.dart';

void main() {
  test('food order moves through the four steps with plain wording', () {
    OrderProgress f(String s) => OrderProgress.of(service: 'LesEat', status: s);
    expect(f('pending').headline, 'Waiting for the store to confirm');
    expect(f('pending').stepIndex, 0);
    expect(f('cooking').headline, 'Your food is being prepared');
    expect(f('cooking').stepIndex, 1);
    expect(f('ready_for_pickup').stepIndex, 1);
    expect(f('on_the_way').headline, 'Your order is on the way');
    expect(f('on_the_way').stepIndex, 2);
    expect(f('on_the_way').stepLabels.last, 'Delivered');
  });

  test('ride uses ride wording and labels', () {
    final p = OrderProgress.of(service: 'LesRide', status: 'accepted');
    expect(p.headline, 'Your driver is on the way');
    expect(p.stepLabels[1], 'Driver coming');
    expect(
      OrderProgress.of(service: 'LesRide', status: 'searching_driver').headline,
      'Finding you a driver',
    );
  });

  test('scheduled shows the time when parseable and degrades when not', () {
    final ok = OrderProgress.of(
      service: 'LesEat',
      status: 'scheduled',
      scheduledAt: '2026-11-23T07:30:00Z',
    );
    expect(ok.headline, startsWith('Scheduled for Nov 23'));
    expect(
      OrderProgress.of(service: 'LesEat', status: 'scheduled').headline,
      'Scheduled',
    );
  });

  test('unknown statuses fall back to a readable label', () {
    final p = OrderProgress.of(service: 'LesGo', status: 'awaiting_review');
    expect(p.headline, 'Awaiting review');
    expect(p.stepIndex, 0);
    expect(OrderProgress.of(service: 'LesGo', status: null).headline, 'In progress');
  });
}
