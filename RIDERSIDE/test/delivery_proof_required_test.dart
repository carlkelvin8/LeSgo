import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/di/injection.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/core/services/orders_api.dart';

class _Client implements DioClient {
  @override
  final Dio dio;
  _Client(this.dio);
  @override
  void initialize() {}
}

void main() {
  for (final proofs in <List<dynamic>>[
    [],
    ['', ' ', null],
    ['proof_images/42/delivery.jpg'],
  ]) {
    test('Completion requires persisted photo: $proofs', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      var patches = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'PATCH') patches++;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {'id': 42, 'proof_images': proofs},
                },
              ),
            );
          },
        ),
      );
      getIt.registerSingleton<DioClient>(_Client(dio));
      addTearDown(() => getIt.reset());
      if (proofs.contains('proof_images/42/delivery.jpg')) {
        await OrdersApi.updateOrderStatus(42, 'completed');
        expect(patches, 1);
      } else {
        await expectLater(
          OrdersApi.updateOrderStatus(42, 'completed'),
          throwsException,
        );
        expect(patches, 0);
      }
    });
  }
  test('Failed proof verification never submits completion', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var patches = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'PATCH') patches++;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    getIt.registerSingleton<DioClient>(_Client(dio));
    addTearDown(() => getIt.reset());
    await expectLater(
      OrdersApi.updateOrderStatus(42, 'completed'),
      throwsException,
    );
    expect(patches, 0);
  });
}
