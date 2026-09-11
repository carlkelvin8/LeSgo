import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/exceptions/client_rate_limit_exception.dart';
import 'package:lesgo/core/utils/api_error_mapper.dart';

void main() {
  group('ApiErrorMapper', () {
    test('maps connection timeout to friendly bilingual message', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(msg, contains('timed out'));
      expect(msg, contains('Nag-timeout'));
      expect(msg, isNot(contains('DioException')));
    });

    test('maps 502 to server busy message', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/wallets/my'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/wallets/my'),
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(msg, contains('Server is busy'));
      expect(msg, isNot(contains('DioException')));
    });

    test('uses API message when present', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/orders'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/orders'),
            statusCode: 422,
            data: {'message': 'Insufficient wallet balance'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(msg, 'Insufficient wallet balance');
    });

    test('maps a 401 API response to an expired-session message', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/support/tickets'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/support/tickets'),
            statusCode: 401,
            data: {'message': 'Unauthenticated.'},
          ),
          type: DioExceptionType.badResponse,
        ),
        fallbackEn: 'Could not load support tickets.',
      );

      expect(msg, contains('session has expired'));
      expect(msg, isNot(contains('Unauthenticated')));
    });

    test('maps 429 with retry-after header', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/orders'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/orders'),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['15'],
            }),
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(msg, contains('15 second'));
      expect(msg, contains('Masyadong maraming'));
      expect(
        ApiErrorMapper.isRateLimited(
          DioException(
            requestOptions: RequestOptions(path: '/v1/orders'),
            response: Response(
              requestOptions: RequestOptions(path: '/v1/orders'),
              statusCode: 429,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
        isTrue,
      );
    });

    test('maps client rate limit exception', () {
      final msg = ApiErrorMapper.message(const ClientRateLimitException(8));
      expect(msg, contains('8 second'));
      expect(
        ApiErrorMapper.isRateLimited(const ClientRateLimitException(1)),
        isTrue,
      );
    });

    test('sanitizes raw technical strings', () {
      final msg = ApiErrorMapper.message(
        'DioException [connection error]: Failed host lookup',
      );
      expect(msg, isNot(contains('DioException')));
      expect(msg, contains('Something went wrong'));
    });
  });
}
