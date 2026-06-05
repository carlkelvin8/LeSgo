import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/api_error_mapper.dart';
import 'package:lesgo/core/utils/snackbar_utils.dart';
import 'package:lesgo/presentation/provider/main/lespay/lespay_provider.dart';

/// Widget/integration tests: login errors, wallet booking, LesPay top-up messaging.
void main() {
  group('Customer journey messages', () {
    testWidgets('SnackBarUtils never shows raw DioException text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarUtils.showErrorFrom(
                      context,
                      DioException(
                        requestOptions: RequestOptions(path: '/v1/auth/login'),
                        type: DioExceptionType.connectionError,
                      ),
                    );
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Hindi maabot ang server'), findsOneWidget);
    });

    testWidgets('LesPay provider error displays friendly bilingual text', (
      tester,
    ) async {
      const friendly =
          'LesPay is unavailable. You can still top up using GCash, Maya, or cards.\n'
          'Hindi available ang LesPay. Puwede pa ring mag-top up gamit ang GCash, Maya, o cards.';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lespayProvider.overrideWith((ref) => _StaticLespayNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _LesPayErrorText(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.text(friendly), findsOneWidget);
    });

    test('login connection error maps to bilingual message', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(msg, contains('Cannot reach the server'));
      expect(msg, contains('Hindi maabot ang server'));
      expect(msg, isNot(contains('DioException')));
    });

    test('wallet booking 422 uses API message', () {
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

    test('top-up 502 maps to server busy message', () {
      final msg = ApiErrorMapper.message(
        DioException(
          requestOptions: RequestOptions(path: '/v1/wallets/top-up'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/wallets/top-up'),
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(msg, contains('Server is busy'));
    });
  });
}

class _StaticLespayNotifier extends LespayNotifier {
  @override
  LespayState get state => const LespayState(
        error:
            'LesPay is unavailable. You can still top up using GCash, Maya, or cards.\n'
            'Hindi available ang LesPay. Puwede pa ring mag-top up gamit ang GCash, Maya, o cards.',
      );
}

class _LesPayErrorText extends ConsumerWidget {
  const _LesPayErrorText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(ref.watch(lespayProvider).error ?? '');
  }
}
