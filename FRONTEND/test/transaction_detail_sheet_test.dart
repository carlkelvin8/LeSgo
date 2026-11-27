import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/domain/entities/transactions/transaction.dart';
import 'package:lesgo/presentation/widgets/transactions/order_transaction_detail_sheet.dart';

class _Orders implements OrderRemoteDataSource {
  @override
  Future<List<String>> fetchProofImages(int orderId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Transaction _t({
  TransactionStatus status = TransactionStatus.cancelled,
  PaymentStatus pay = PaymentStatus.pending,
}) => Transaction(
  id: '11',
  serviceName: 'LesEat',
  serviceId: 3,
  date: '2026-11-19T00:04:00Z',
  pickupLocation: 'Claveria, Cagayan',
  dropoffLocation: 'Centro I, Claveria',
  amount: 233,
  status: status,
  rawStatus: status.name,
  paymentStatus: pay,
  paymentMethod: 'cash',
  items: [TransactionItem(name: '1-pc Chickenjoy', quantity: 2, price: 89)],
);

Future<void> _open(WidgetTester tester, Transaction t) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OrderTransactionDetailSheet(
          transaction: t,
          controller: ScrollController(),
          formatDate: (d) => 'Nov 19, 2026',
          statusLabel: (s) => s,
          sharingReceipt: false,
          onDownloadReceipt: () {},
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(() => getIt.registerSingleton<OrderRemoteDataSource>(_Orders()));
  tearDown(getIt.reset);

  testWidgets('never shows the order number and explains a cancelled order', (tester) async {
    await _open(tester, _t());
    expect(find.textContaining('#11'), findsNothing);
    expect(find.textContaining('Order #'), findsNothing);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Not charged'), findsWidgets);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('1-pc Chickenjoy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a completed, paid order reads Completed and Paid', (tester) async {
    await _open(tester, _t(status: TransactionStatus.completed, pay: PaymentStatus.paid));
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Download receipt (PDF)'), findsOneWidget);
  });
}
