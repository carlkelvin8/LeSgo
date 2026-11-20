import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/leseat_status_text.dart';

void main() {
  group('LesEatStatusText', () {
    const known = [
      'pending',
      'accepted',
      'driver_arrived_at_pickup',
      'in_progress',
      'ready_for_pickup',
      'picked_up',
      'in_transit',
      'completed',
      'cancelled',
      'failed',
    ];

    test('every backend status has a readable title and subtext', () {
      for (final status in known) {
        expect(LesEatStatusText.title(status), isNot(contains('_')));
        expect(LesEatStatusText.subtext(status), isNotEmpty);
      }
    });

    test('is case-insensitive', () {
      expect(LesEatStatusText.title('READY_FOR_PICKUP'), 'Order Ready');
      expect(
        LesEatStatusText.subtext('READY_FOR_PICKUP'),
        'Your food is ready and waiting for the rider',
      );
    });

    test('scheduled orders are not described as being prepared', () {
      expect(LesEatStatusText.title('scheduled'), 'Scheduled');
      expect(LesEatStatusText.subtext('scheduled'), contains('scheduled'));
      expect(
        LesEatStatusText.subtext('scheduled'),
        isNot(contains('being prepared')),
      );
    });

    test('unknown statuses get a neutral subtext and a humanized title', () {
      expect(LesEatStatusText.title('awaiting_payment'), 'Awaiting payment');
      expect(LesEatStatusText.title(''), 'Order Update');
      expect(
        LesEatStatusText.subtext('awaiting_payment'),
        isNot(contains('being prepared')),
      );
    });
  });
}
