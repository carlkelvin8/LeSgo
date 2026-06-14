import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/screen_auto_refresh.dart';

void main() {
  test('kRiderMainAutoRefreshInterval is slower than detail refresh', () {
    expect(
      kRiderMainAutoRefreshInterval.inSeconds,
      greaterThan(kScreenAutoRefreshInterval.inSeconds),
    );
  });
}
