import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderWalletPaymentScreen extends ConsumerStatefulWidget {
  final RiderTopUpCheckout checkout;

  const RiderWalletPaymentScreen({super.key, required this.checkout});

  @override
  ConsumerState<RiderWalletPaymentScreen> createState() =>
      _RiderWalletPaymentScreenState();
}

class _RiderWalletPaymentScreenState
    extends ConsumerState<RiderWalletPaymentScreen> {
  bool _openedBrowser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPaymentPage());
  }

  Future<void> _openPaymentPage() async {
    final uri = Uri.parse(widget.checkout.invoiceUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (mounted) {
      setState(() => _openedBrowser = launched);
      if (!launched) {
        SnackBarUtils.showError(
          context,
          'Could not open payment page. Tap the button below.',
        );
      }
    }
  }

  Future<void> _confirmPayment() async {
    final success = await ref
        .read(riderWalletProvider.notifier)
        .completeTopUp(widget.checkout);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? 'Payment verification failed. Try again in a moment.',
      );
    }
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'PHP ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? const Color(0xFF5F2D82) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(riderWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              _openedBrowser
                  ? 'Finish payment in your browser (GCash, Maya, or card), then return here and confirm.'
                  : 'Open the payment page, complete payment, then confirm below.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            _summaryRow('LesPay credit', widget.checkout.walletAmount),
            _summaryRow('Top-up fee (3%)', widget.checkout.feeAmount),
            const Divider(),
            _summaryRow(
              'Total to pay',
              widget.checkout.totalCharge,
              bold: true,
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _openPaymentPage,
              child: const Text('Open payment page'),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            ElevatedButton(
              onPressed: walletState.isProcessingTopUp ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: walletState.isProcessingTopUp
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("I've completed payment"),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          ],
        ),
      ),
    );
  }
}
