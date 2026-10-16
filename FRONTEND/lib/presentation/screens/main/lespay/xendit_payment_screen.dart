import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/services/order_receipt_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../domain/entities/transactions/transaction.dart';
import '../../../provider/main/lespay/lespay_provider.dart';

class XenditPaymentScreen extends ConsumerStatefulWidget {
  final TopUpCheckout checkout;

  const XenditPaymentScreen({super.key, required this.checkout});

  @override
  ConsumerState<XenditPaymentScreen> createState() =>
      _XenditPaymentScreenState();
}

class _XenditPaymentScreenState extends ConsumerState<XenditPaymentScreen> {
  late final WebViewController _webViewController;
  bool _isConfirming = false;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Payment checkout URL: ${widget.checkout.invoiceUrl} '
        '(provider: ${widget.checkout.provider})');
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme == 'lesgo') {
              _handleRedirect(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
            if (mounted) setState(() => _webViewFailed = true);
          },
          onPageFinished: (url) {
            // If page loads but is empty/error, mark as failed after timeout
            debugPrint('WebView page finished: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkout.invoiceUrl));
  }

  void _handleRedirect(Uri uri) {
    if (uri.path.contains('success')) {
      _confirmPayment();
    } else if (uri.path.contains('failure')) {
      SnackBarUtils.showError(context, 'Payment was cancelled.');
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.checkout.invoiceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Could not open payment page.');
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    final success = await ref
        .read(lespayProvider.notifier)
        .completeTopUp(widget.checkout);

    if (!mounted) return;

    setState(() => _isConfirming = false);

    if (success) {
      SnackBarUtils.showSuccess(
        context,
        '₱${widget.checkout.walletAmount.toStringAsFixed(2)} added to your wallet!',
      );
      if (mounted) {
        final download = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Payment successful',
              style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'Download your LesPay receipt as PDF?',
              style: TextStyle(fontFamily: 'TT Fors'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                ),
                child: const Text('Download PDF'),
              ),
            ],
          ),
        );
        if (download == true && mounted) {
          try {
            await OrderReceiptService.shareWalletReceipt(
              amount: widget.checkout.walletAmount,
              description: 'LesPay top-up',
              reference: widget.checkout.invoiceId,
              date: DateTime.now().toIso8601String(),
              isCredit: true,
              paymentStatus: PaymentStatus.paid,
              feeAmount: widget.checkout.feeAmount,
              totalCharged: widget.checkout.totalCharge,
            );
          } catch (_) {
            if (mounted) {
              SnackBarUtils.showError(context, 'Could not generate receipt.');
            }
          }
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final error = ref.read(lespayProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? 'Payment verification failed. Try again in a moment.',
      );
    }
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.foreground(context, Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Payment',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 8),
            ),
            child: Column(
              children: [
                _summaryRow(
                  context,
                  'Wallet credit',
                  widget.checkout.walletAmount,
                ),
                _summaryRow(
                  context,
                  'Top-up fee (1.5%)',
                  widget.checkout.feeAmount,
                ),
                Divider(height: ResponsiveUtils.spacing(context, 12)),
                _summaryRow(
                  context,
                  'Total to pay',
                  widget.checkout.totalCharge,
                  bold: true,
                ),
              ],
            ),
          ),
          if (_webViewFailed)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 16),
              ),
              child: Text(
                'In-app browser could not load the payment page. Open in your browser instead.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          Expanded(
            child: _webViewFailed
                ? Center(
                    child: ElevatedButton(
                      onPressed: _openInBrowser,
                      child: const Text('Open payment page'),
                    ),
                  )
                : WebViewWidget(controller: _webViewController),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                      onPressed: _openInBrowser,
                      child: const Text('Open in browser'),
                    ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  ElevatedButton(
                    onPressed: lespayState.isProcessingTopUp || _isConfirming
                        ? null
                        : _confirmPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F2D82),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 14),
                      ),
                    ),
                    child: lespayState.isProcessingTopUp || _isConfirming
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "I've completed payment",
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
