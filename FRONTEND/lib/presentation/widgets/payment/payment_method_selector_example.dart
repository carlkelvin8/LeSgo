import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../../provider/main/payment_gateway/payment_gateway_provider.dart';

/// Example widget showing how to use PaymentGatewayProvider
/// This can be used in checkout screens for payment method selection
class PaymentMethodSelectorExample extends ConsumerStatefulWidget {
  final double amount;
  final Function(String method)? onMethodSelected;

  const PaymentMethodSelectorExample({
    Key? key,
    required this.amount,
    this.onMethodSelected,
  }) : super(key: key);

  @override
  ConsumerState<PaymentMethodSelectorExample> createState() =>
      _PaymentMethodSelectorExampleState();
}

class _PaymentMethodSelectorExampleState
    extends ConsumerState<PaymentMethodSelectorExample> {
  String _selectedMethod = 'cod';

  @override
  void initState() {
    super.initState();
    // Validate wallet balance on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentGatewayProvider.notifier).validateWalletBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);
    final gatewayState = ref.watch(paymentGatewayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Cash on Delivery
        _buildPaymentOption(
          value: 'cod',
          title: 'Cash on Delivery',
          subtitle: 'Pay with cash when order arrives',
          icon: Icons.money,
          enabled: true,
        ),

        // Wallet
        _buildPaymentOption(
          value: 'wallet',
          title: 'LesPay Wallet',
          subtitle: gatewayState.canUseWallet
              ? 'Balance: ₱${lespayState.balance.toStringAsFixed(2)}'
              : 'Insufficient balance (₱${lespayState.balance.toStringAsFixed(2)})',
          icon: Icons.account_balance_wallet,
          enabled: gatewayState.canUseWallet,
          trailing: gatewayState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),

        // Xendit (Card/E-wallet)
        _buildPaymentOption(
          value: 'xendit',
          title: 'Card / E-wallet',
          subtitle: 'Pay with credit/debit card or e-wallet',
          icon: Icons.credit_card,
          enabled: true,
        ),

        const SizedBox(height: 16),

        // Show wallet threshold info if wallet is selected but insufficient
        if (_selectedMethod == 'wallet' && !gatewayState.canUseWallet)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insufficient Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      if (gatewayState.walletThreshold != null)
                        Text(
                          'Minimum balance required: ₱${gatewayState.walletThreshold!.minimumThreshold.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMethod == 'wallet' && !gatewayState.canUseWallet
                ? null
                : () {
                    widget.onMethodSelected?.call(_selectedMethod);
                    _handlePayment();
                  },
            child: Text(
              _selectedMethod == 'xendit'
                  ? 'Proceed to Payment'
                  : 'Confirm Order',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    Widget? trailing,
  }) {
    return Card(
      color: _selectedMethod == value
          ? Colors.blue.shade50
          : (enabled ? null : Colors.grey.shade100),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedMethod,
        onChanged: enabled
            ? (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMethod = newValue;
                  });
                }
              }
            : null,
        title: Row(
          children: [
            Icon(icon, color: enabled ? null : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled ? null : Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? null : Colors.grey,
          ),
        ),
        secondary: trailing,
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedMethod == 'xendit') {
      // Create invoice and open payment URL
      final gatewayNotifier = ref.read(paymentGatewayProvider.notifier);
      
      final invoice = await gatewayNotifier.createOrderPaymentInvoice(
        orderId: 0, // TODO: Get actual order ID
        amount: widget.amount,
        paymentMethod: 'xendit',
        context: context,
      );

      if (invoice != null && invoice.invoiceUrl != null) {
        // TODO: Open invoice URL in webview or browser
        // Example:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PaymentWebViewScreen(
        //       url: invoice.invoiceUrl!,
        //       invoiceId: invoice.invoiceId,
        //     ),
        //   ),
        // );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment URL: ${invoice.invoiceUrl}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      // For COD and Wallet, proceed with order creation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment method selected: $_selectedMethod'),
          ),
        );
      }
    }
  }
}
