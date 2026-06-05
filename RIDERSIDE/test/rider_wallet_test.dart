import 'package:flutter_test/flutter_test.dart';
import 'package:frontend2/core/utils/lespay_topup_fee.dart';
import 'package:frontend2/core/utils/wallet_response_parser.dart';
import 'package:frontend2/presentation/provider/main/riderside/rider_wallet_provider.dart';

void main() {
  group('WalletResponseParser', () {
    test('parseListBody reads data array', () {
      final list = WalletResponseParser.parseListBody({
        'success': true,
        'data': [
          {'id': 1, 'type': 'credit', 'amount': 100},
        ],
      });
      expect(list.length, 1);
    });

    test('extractInvoiceMap reads flat data invoice', () {
      final invoice = WalletResponseParser.extractInvoiceMap({
        'success': true,
        'data': {
          'invoice_id': 'inv_123',
          'invoice_url': 'https://checkout.example/inv_123',
        },
      });
      expect(invoice?['invoice_id'], 'inv_123');
      expect(invoice?['invoice_url'], contains('checkout'));
    });

    test('extractInvoiceMap reads nested invoice object', () {
      final invoice = WalletResponseParser.extractInvoiceMap({
        'data': {
          'invoice': {
            'invoice_id': 'inv_nested',
            'invoice_url': 'https://pay.example',
          },
        },
      });
      expect(invoice?['invoice_id'], 'inv_nested');
    });

    test('computeTotalDeposits sums top-up credits first', () {
      final total = WalletResponseParser.computeTotalDeposits([
        {'type': 'credit', 'amount': 500, 'description': 'LesPay top-up via Xendit'},
        {'type': 'credit', 'amount': 50, 'description': 'Refund'},
        {'type': 'debit', 'amount': 10, 'description': 'Booking'},
      ]);
      expect(total, 500);
    });

    test('computeTotalDeposits falls back to all credits', () {
      final total = WalletResponseParser.computeTotalDeposits([
        {'type': 'credit', 'amount': 100, 'description': 'Admin credit'},
        {'type': 'credit', 'amount': 50, 'description': 'Bonus'},
      ]);
      expect(total, 150);
    });

    test('normalizePhilippineMobile formats 09 number', () {
      expect(
        WalletResponseParser.normalizePhilippineMobile('9171234567'),
        '09171234567',
      );
      expect(
        WalletResponseParser.normalizePhilippineMobile('+639171234567'),
        '09171234567',
      );
    });

    test('isInvoicePaidStatus recognizes paid states', () {
      expect(WalletResponseParser.isInvoicePaidStatus('PAID'), isTrue);
      expect(WalletResponseParser.isInvoicePaidStatus('pending'), isFalse);
    });
  });

  group('LespayTopupFee', () {
    test('calculate applies 3% fee', () {
      final pricing = LespayTopupFee.calculate(500);
      expect(pricing.walletAmount, 500);
      expect(pricing.feeAmount, 15);
      expect(pricing.totalCharge, 515);
    });
  });

  group('RiderWalletState', () {
    test('linkedAccountSubtitle shows masked number', () {
      const state = RiderWalletState(
        linkedAccounts: [
          {
            'provider': 'gcash',
            'is_verified': true,
            'meta': {'account_number': '09171234567'},
          },
        ],
      );
      expect(state.isProviderLinked('gcash'), isTrue);
      expect(state.linkedAccountSubtitle('gcash'), 'Linked •••• 4567');
    });

    test('linkedAccountSubtitle when not linked', () {
      const state = RiderWalletState();
      expect(state.isProviderLinked('maya'), isFalse);
      expect(state.linkedAccountSubtitle('maya'), 'Not linked — tap to add');
    });
  });
}
