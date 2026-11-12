import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';

/// Only [dio] is used by the order datasource; the rest of DioClient is not.
class _FakeDioClient implements DioClient {
  _FakeDioClient(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CreateOrderRequestDto _request() => CreateOrderRequestDto(
      serviceId: 1,
      partnerId: 41,
      estimatedDistanceM: 3000,
      pickup: OrderAddressDto(address: 'Store', lat: 18.6, lng: 121.0),
      dropoff: OrderAddressDto(address: 'Home', lat: 18.61, lng: 121.01),
    );

OrderRemoteDataSource _refusedWith(int status, Map<String, dynamic> body) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) => handler.reject(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: status, data: body),
          type: DioExceptionType.badResponse,
        ),
      ),
    ),
  );
  return OrderRemoteDataSource(_FakeDioClient(dio));
}

void main() {
  group('createOrder shows the server\'s reason', () {
    test('a store that blocked the customer says so', () {
      final datasource = _refusedWith(403, {
        'success': false,
        'message': 'This store is not accepting orders from your account.',
      });

      expect(
        datasource.createOrder(_request()),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'This store is not accepting orders from your account.',
            ),
          ),
        ),
      );
    });

    test('a closed store keeps its own message', () {
      final datasource = _refusedWith(422, {
        'success': false,
        'message': 'This store is currently closed and not accepting orders.',
      });

      expect(
        datasource.createOrder(_request()),
        throwsA(
          predicate(
            (e) => e.toString().contains('currently closed'),
          ),
        ),
      );
    });
  });
}
