import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/payment_gateway/payment_gateway_provider.dart';

/// Whether a gateway invoice status means the customer has paid.
bool isInvoicePaidStatus(String? status) {
  final s = status?.toLowerCase();
  return s == 'paid' || s == 'completed';
}

/// Xendit / gateway checkout for order payments (GCash, PayMaya, card).
class OrderDigitalPaymentScreen extends ConsumerStatefulWidget {
  const OrderDigitalPaymentScreen({
    super.key,
    required this.orderId,
    required this.invoiceId,
    required this.invoiceUrl,
    required this.amount,
    required this.paymentMethod,
    required this.serviceLabel,
  });

  final int orderId;
  final String invoiceId;
  final String invoiceUrl;
  final double amount;
  final String paymentMethod;
  final String serviceLabel;

  @override
  ConsumerState<OrderDigitalPaymentScreen> createState() =>
      _OrderDigitalPaymentScreenState();
}

class _OrderDigitalPaymentScreenState
    extends ConsumerState<OrderDigitalPaymentScreen> {
  late final WebViewController _webViewController;
  bool _isConfirming = false;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
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
            if (mounted) setState(() => _webViewFailed = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoiceUrl));
  }

  void _handleRedirect(Uri uri) {
    if (uri.path.contains('success')) {
      _confirmPayment();
    } else if (uri.path.contains('failure') || uri.path.contains('cancel')) {
      SnackBarUtils.showError(context, 'Payment was cancelled.');
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.invoiceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Could not open payment page.');
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    final invoice = await ref
        .read(paymentGatewayProvider.notifier)
        .checkInvoiceStatus(invoiceId: widget.invoiceId, context: context);

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (invoice != null && isInvoicePaidStatus(invoice.status)) {
      SnackBarUtils.showSuccess(
        context,
        'Payment successful! Your ${widget.serviceLabel} order is confirmed.',
      );
      Navigator.of(context).pop(true);
      return;
    }

    SnackBarUtils.showError(
      context,
      ref.read(paymentGatewayProvider).error ??
          'Payment not completed yet. Finish paying, then tap Confirm.',
    );
  }

  /// Back press: the customer may have paid already, so verify before the
  /// caller cancels the order. Pops true when paid, false only when the invoice
  /// is confirmed unpaid and the user agrees to leave, and null when the status
  /// could not be verified (the caller must not cancel in that case).
  Future<void> _handleBack() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    final invoice = await ref
        .read(paymentGatewayProvider.notifier)
        .checkInvoiceStatus(invoiceId: widget.invoiceId, context: context);
    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (invoice != null && isInvoicePaidStatus(invoice.status)) {
      SnackBarUtils.showSuccess(
        context,
        'Payment successful! Your ${widget.serviceLabel} order is confirmed.',
      );
      Navigator.of(context).pop(true);
      return;
    }

    final verified = invoice != null;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(verified ? 'Leave payment?' : 'Could not verify payment'),
        content: Text(
          verified
              ? 'Your payment has not been received. If you leave, this order will be cancelled.'
              : 'We could not check whether your payment went through. If you already paid, stay here and tap Confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(verified ? 'Leave and cancel' : 'Leave anyway'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop(verified ? false : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gatewayState = ref.watch(paymentGatewayProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Pay for ${widget.serviceLabel}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${widget.orderId}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: AppColors.foreground(context, Colors.grey[700]!),
                    ),
                  ),
                  Text(
                    Money.format(widget.amount),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent(context, Color(0xFF5F2D82)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _webViewFailed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.open_in_browser, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Could not load payment page in app.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _openInBrowser,
                              child: const Text('Open in browser'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _webViewController),
            ),
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: gatewayState.isCheckingStatus || _isConfirming
                      ? null
                      : _confirmPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.buttonFill(context),
                    foregroundColor: AppColors.onButton(context),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 14),
                    ),
                  ),
                  child: gatewayState.isCheckingStatus || _isConfirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm payment'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
