import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/network/offline_queue_storage.dart';
import 'package:lezgo_rider/core/network/offline_request_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OfflineQueueStorage saves and restores request records', () async {
    final records = [
      OfflineRequestRecord(
        method: 'PATCH',
        path: '/v1/orders/12/status',
        baseUrl: 'https://api.example.com',
        data: {'status': 'picked_up'},
      ),
    ];

    await OfflineQueueStorage.save(records);
    final restored = await OfflineQueueStorage.load();

    expect(restored.length, 1);
    expect(restored.first.method, 'PATCH');
    expect(restored.first.path, '/v1/orders/12/status');
    expect(restored.first.data, {'status': 'picked_up'});
  });

  test('OfflineQueueStorage clears storage when queue is empty', () async {
    await OfflineQueueStorage.save([
      OfflineRequestRecord(
        method: 'POST',
        path: '/v1/orders/1/accept',
        baseUrl: 'https://api.example.com',
      ),
    ]);

    await OfflineQueueStorage.save([]);
    final restored = await OfflineQueueStorage.load();
    expect(restored, isEmpty);
  });
}
