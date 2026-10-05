import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/network/offline_exceptions.dart';
import 'package:lezgo_rider/core/utils/offline_feedback_utils.dart';

void main() {
  test('isOfflineQueuedError detects OfflineQueuedException', () {
    expect(isOfflineQueuedError(const OfflineQueuedException()), isTrue);
  });

  test('isOfflineQueuedError detects queued message text', () {
    expect(
      isOfflineQueuedError(
        Exception('You\'re offline. This action will retry when connection returns.'),
      ),
      isTrue,
    );
  });
}
