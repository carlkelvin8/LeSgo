import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/app_localization.dart';
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
    extends ConsumerState<RiderWalletPaymentScreen>
    with WidgetsBindingObserver {
  bool _openedBrowser = false;
  bool _autoConfirmed = false;
  bool _popped = false;
  Timer? _pollTimer;

  void _popWithSuccess() {
    if (!mounted || _popped) return;
    _popped = true;
    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPaymentPage());
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _autoConfirmOnResume();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rider pays in the external browser and returns to the app without
    // tapping "I completed payment" — verify + refresh the wallet for them.
    if (state == AppLifecycleState.resumed && mounted && !_autoConfirmed) {
      _autoConfirmOnResume();
    }
  }

  Future<void> _autoConfirmOnResume() async {
    if (!mounted ||
        _popped ||
        _autoConfirmed ||
        ref.read(riderWalletProvider).isProcessingTopUp) {
      return;
    }
    _autoConfirmed = true;
    final notifier = ref.read(riderWalletProvider.notifier);

    // Cheap check first — if the gateway still reports unpaid, stay quiet and
    // let the user finish manually (poll also completes the top-up server-side
    // when it IS paid).
    final paid = await notifier.pollInvoicePaid(widget.checkout.invoiceId);
    if (!mounted || _popped) return;
    if (!paid) {
      // Allow another try on the next resume instead of a stuck "not confirmed".
      _autoConfirmed = false;
      return;
    }

    final success = await notifier.completeTopUp(widget.checkout);
    if (!mounted) return;

    if (success) {
      _popWithSuccess();
    }
    _autoConfirmed = false;
  }

  Future<void> _openPaymentPage() async {
    final uri = Uri.tryParse(widget.checkout.invoiceUrl);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (mounted) {
        setState(() => _openedBrowser = false);
        SnackBarUtils.showError(
          context,
          AppLocalization.translate(
            'could_not_open_payment_page',
            ref.read(appLanguageProvider),
          ),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) {
      setState(() => _openedBrowser = launched);
      if (!launched) {
        SnackBarUtils.showError(
          context,
          AppLocalization.translate(
            'could_not_open_payment_page',
            ref.read(appLanguageProvider),
          ),
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
      _popWithSuccess();
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ??
            AppLocalization.translate(
              'payment_verification_failed',
              ref.read(appLanguageProvider),
            ),
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
    final lang = ref.watch(appLanguageProvider);
    final walletState = ref.watch(riderWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalization.translate('complete_payment', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              _openedBrowser
                  ? AppLocalization.translate('finish_payment_in_browser', lang)
                  : AppLocalization.translate('open_payment_page_desc', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            _summaryRow(
              AppLocalization.translate('lespay_credit', lang),
              widget.checkout.walletAmount,
            ),
            _summaryRow(
              AppLocalization.translate('top_up_fee_percent', lang),
              widget.checkout.feeAmount,
            ),
            const Divider(),
            _summaryRow(
              AppLocalization.translate('total_to_pay', lang),
              widget.checkout.totalCharge,
              bold: true,
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _openPaymentPage,
              child: Text(AppLocalization.translate('open_payment_page', lang)),
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
                  : Text(
                      AppLocalization.translate('i_completed_payment', lang),
                    ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          ],
        ),
      ),
    );
  }
}
