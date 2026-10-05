import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';

class TestWallet extends RiderWalletNotifier {
  TestWallet(Dio client) : super(client: client);

  @override
  Future<void> loadWallet({bool silent = false}) async {}
}

void main() {
  const checkout = RiderTopUpCheckout(
    invoiceId: 'checkout-rider',
    invoiceUrl: 'https://checkout.example/pay',
    walletAmount: 100,
    feeAmount: 1.5,
    totalCharge: 101.5,
  );

  test(
    'confirmed top-up immediately reflects the server balance, including zero',
    () async {
      for (final balance in ['350.00', '0.00', '-25.00']) {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              expect(request.path, '/v1/wallets/my/topup');
              expect(request.data['gateway_reference'], checkout.invoiceId);
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': {'balance': balance},
                  },
                ),
              );
            },
          ),
        );
        final wallet = TestWallet(dio);
        expect(await wallet.completeTopUp(checkout), isTrue);
        expect(wallet.state.balance, double.parse(balance));
        expect(wallet.state.isProcessingTopUp, isFalse);
        wallet.dispose();
      }
    },
  );

  test(
    'invoice or malformed response is not accepted as wallet credit',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': {'invoice_id': 'pending-invoice'},
                },
              ),
            );
          },
        ),
      );
      final wallet = TestWallet(dio);
      expect(await wallet.completeTopUp(checkout), isFalse);
      expect(wallet.state.balance, 0);
      wallet.dispose();
    },
  );

  test(
    'failed checkout does not create a second invoice via fallback',
    () async {
      final dio = Dio();
      var requests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests++;
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: request, statusCode: 503),
              ),
            );
          },
        ),
      );
      final wallet = TestWallet(dio);
      expect(await wallet.startTopUp(100), isNull);
      expect(requests, 1);
      wallet.dispose();
    },
  );
}
