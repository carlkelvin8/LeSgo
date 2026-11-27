import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/presentation/widgets/chat/chat_report_sheet.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/orders/merchant_customer_safety_handlers.dart';

/// A Dio that records each request and answers with [reply].
class _Recorder {
  _Recorder(this.reply) {
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          final error = failWith;
          if (error != null) {
            handler.reject(
              DioException(
                requestOptions: request,
                response: Response(
                  requestOptions: request,
                  statusCode: error.$1,
                  data: {'success': false, 'message': error.$2},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.resolve(Response(requestOptions: request, data: reply));
        },
      ),
    );
  }

  final Map<String, dynamic> reply;
  late final Dio dio;
  final calls = <RequestOptions>[];
  (int, String)? failWith;
}

void main() {
  group('MerchantRemoteDataSource customer safety', () {
    test('isCustomerBlocked reads the server flag', () async {
      final http = _Recorder({
        'success': true,
        'data': {'customer_blocked': true},
      });

      final blocked =
          await MerchantRemoteDataSource(dio: http.dio).isCustomerBlocked(7);

      expect(blocked, isTrue);
      expect(http.calls.single.method, 'GET');
      expect(http.calls.single.path, '/v1/orders/7/customer-safety');
    });

    test('isCustomerBlocked is false when the flag is missing', () async {
      final http = _Recorder({'success': true, 'data': {}});

      expect(await MerchantRemoteDataSource(dio: http.dio).isCustomerBlocked(7),
          isFalse);
    });

    test('reportCustomer posts the reason, details and block choice', () async {
      final http = _Recorder({
        'success': true,
        'data': {'customer_blocked': true},
      });

      await MerchantRemoteDataSource(dio: http.dio).reportCustomer(
        7,
        reason: 'harassment',
        details: 'Abusive on the phone',
        block: true,
      );

      final call = http.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/v1/orders/7/report-customer');
      expect(call.data, {
        'reason': 'harassment',
        'details': 'Abusive on the phone',
        'block': true,
      });
    });

    test('reportCustomer leaves out empty details', () async {
      final http = _Recorder({'success': true, 'data': {}});

      await MerchantRemoteDataSource(dio: http.dio)
          .reportCustomer(7, reason: 'other', details: '');

      expect(http.calls.single.data, {'reason': 'other', 'block': false});
    });

    test('setCustomerBlocked posts to block and deletes to unblock', () async {
      final blockHttp = _Recorder({
        'success': true,
        'data': {'customer_blocked': true},
      });
      final unblockHttp = _Recorder({
        'success': true,
        'data': {'customer_blocked': false},
      });

      expect(
        await MerchantRemoteDataSource(dio: blockHttp.dio)
            .setCustomerBlocked(7, true),
        isTrue,
      );
      expect(
        await MerchantRemoteDataSource(dio: unblockHttp.dio)
            .setCustomerBlocked(7, false),
        isFalse,
      );

      expect(blockHttp.calls.single.method, 'POST');
      expect(blockHttp.calls.single.path, '/v1/orders/7/block-customer');
      expect(unblockHttp.calls.single.method, 'DELETE');
      expect(unblockHttp.calls.single.path, '/v1/orders/7/block-customer');
    });

    test('a server refusal surfaces as a readable message', () async {
      final http = _Recorder({'success': true})
        ..failWith = (403, 'Forbidden');

      expect(
        () => MerchantRemoteDataSource(dio: http.dio).setCustomerBlocked(7, true),
        throwsA(
          predicate((e) => e.toString().contains('Could not block customer')),
        ),
      );
    });
  });

  group('MerchantCustomerSafetyHandlers', () {
    test('the block menu entry follows the current state', () {
      expect(MerchantCustomerSafetyHandlers.blockLabel(false), 'Block customer');
      expect(MerchantCustomerSafetyHandlers.blockLabel(true), 'Unblock customer');
      expect(MerchantCustomerSafetyHandlers.reportLabel, 'Report customer');
    });
  });

  group('ChatReportSheet', () {
    Future<void> openSheet(
      WidgetTester tester, {
      String? blockSubtitle,
      required void Function(ChatReportResult?) onResult,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final result = blockSubtitle == null
                        ? await ChatReportSheet.show(context,
                            targetLabel: 'Andrea Santos')
                        : await ChatReportSheet.show(context,
                            targetLabel: 'Andrea Santos',
                            blockSubtitle: blockSubtitle);
                    onResult(result);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a store sees what blocking means for ordering', (tester) async {
      await openSheet(
        tester,
        blockSubtitle: 'They will no longer be able to order from your store.',
        onResult: (_) {},
      );

      expect(find.text('Report Andrea Santos'), findsOneWidget);
      expect(find.text('Also block Andrea Santos'), findsOneWidget);
      expect(
        find.text('They will no longer be able to order from your store.'),
        findsOneWidget,
      );
      expect(find.text('You will no longer exchange messages.'), findsNothing);
    });

    testWidgets('chat keeps its original wording by default', (tester) async {
      await openSheet(tester, onResult: (_) {});

      expect(find.text('You will no longer exchange messages.'), findsOneWidget);
    });

    testWidgets('submitting returns the reason, details and block choice',
        (tester) async {
      ChatReportResult? result;
      await openSheet(tester, onResult: (r) => result = r);

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
        reason: 'a reason must be chosen first',
      );

      await tester.tap(find.text('Harassment or bullying'));
      await tester.enterText(find.byType(TextField), 'Shouted at my staff');
      await tester.pump();
      await tester.ensureVisible(find.text('Submit report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(result?.reason, 'harassment');
      expect(result?.details, 'Shouted at my staff');
      expect(result?.block, isTrue);
    });
  });
}
