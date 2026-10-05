import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_inbox_provider.dart';

void main() {
  test('RiderInboxState starts empty', () {
    const state = RiderInboxState();
    expect(state.conversations, isEmpty);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('RiderInboxState copyWith clears error', () {
    const state = RiderInboxState(error: 'failed');
    final next = state.copyWith(clearError: true);
    expect(next.error, isNull);
  });
}
