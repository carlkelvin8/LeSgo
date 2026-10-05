import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lesgo/data/data_source/dto/wallet/wallet_dto.dart';
import 'package:lesgo/presentation/provider/main/lespay/lespay_provider.dart';
import 'package:lesgo/presentation/widgets/lespay/lespay_actions_section.dart';
import 'package:lesgo/presentation/widgets/lespay/wallet_card.dart';
import 'package:lesgo/presentation/widgets/lespay/wallet_transactions_section.dart';

const _widths = <double>[320, 360, 390, 414, 560, 700, 1024, 1440];
const _textScales = <double>[1.0, 1.3, 2.0];

class _FakeLespayNotifier extends LespayNotifier {
  _FakeLespayNotifier(LespayState initialState) {
    state = initialState;
  }

  @override
  Future<void> loadWallet() async {}

  @override
  Future<void> loadTransactions() async {}
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  double width,
  double height,
  double textScale,
) async {
  const dpr = 2.0;
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, c) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: c!,
        );
      },
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('WalletCard never overflows across widths and text scales',
      (tester) async {
    for (final width in _widths) {
      for (final scale in _textScales) {
        await _pump(
          tester,
          WalletCard(
            balance: 12345678.90,
            balanceVisible: true,
            onTap: () {},
            onToggleVisibility: () {},
          ),
          width,
          900,
          scale,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'WalletCard overflowed at width=$width textScale=$scale',
        );
      }
    }
  });

  testWidgets('LesPay actions section never overflows in 2-col tiles',
      (tester) async {
    for (final width in _widths) {
      for (final scale in _textScales) {
        await _pump(
          tester,
          const ProviderScope(child: LespayActionsSection()),
          width,
          900,
          scale,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Actions section overflowed at width=$width textScale=$scale',
        );
      }
    }
  });

  testWidgets('Wallet transactions section never overflows', (tester) async {
    final transactions = [
      WalletTransactionDto(
        id: 1,
        walletId: 1,
        type: 'credit',
        amount: 123456.78,
        description:
            'LesPay Top-up from card ending 4242 with a very long description '
            'that must be truncated gracefully',
        reference: 'INV-2026-000000123456789-EXTRA-LONG-REFERENCE',
        status: 'paid',
        createdAt: '2026-09-13T10:00:00Z',
      ),
      WalletTransactionDto(
        id: 2,
        walletId: 1,
        type: 'debit',
        amount: 999.99,
        description: 'Payment to LesGo rider',
        reference: 'PYM-2026-000000987654321-LONG-REFERENCE-HERE',
        status: 'failed',
        createdAt: '2026-09-12T09:30:00Z',
      ),
      WalletTransactionDto(
        id: 3,
        walletId: 1,
        type: 'credit',
        amount: 50.25,
        description: 'Cashback reward',
        status: 'pending',
        createdAt: '2026-09-11T08:15:00Z',
      ),
    ];

    const state = LespayState(
      balance: 12345.67,
      isLoading: false,
      walletLoaded: true,
    );

    for (final width in _widths) {
      for (final scale in _textScales) {
        final overridden = [
          lespayProvider.overrideWith(
            (ref) => _FakeLespayNotifier(
              state.copyWith(transactions: transactions),
            ),
          ),
        ];
        await _pump(
          tester,
          ProviderScope(
            overrides: overridden,
            child: const WalletTransactionsSection(),
          ),
          width,
          1200,
          scale,
        );
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Transactions section overflowed at width=$width textScale=$scale',
        );
      }
    }
  });
}