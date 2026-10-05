import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/rider_package_api.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/riderside/rider_package_provider.dart';

class RiderPackagePaymentScreen extends ConsumerStatefulWidget {
  final RiderPackageUpgradeCheckout checkout;

  const RiderPackagePaymentScreen({super.key, required this.checkout});

  @override
  ConsumerState<RiderPackagePaymentScreen> createState() =>
      _RiderPackagePaymentScreenState();
}

class _RiderPackagePaymentScreenState
    extends ConsumerState<RiderPackagePaymentScreen> {
  bool _openedBrowser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPaymentPage());
  }

  Future<void> _openPaymentPage() async {
    final url = widget.checkout.invoiceUrl;
    if (url == null || url.isEmpty) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
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

  Future<void> _confirmPayment() async {
    final invoiceId = widget.checkout.invoiceId;
    if (invoiceId == null || invoiceId.isEmpty) return;

    final result = await ref
        .read(riderPackageProvider.notifier)
        .confirmXenditUpgrade(invoiceId);

    if (!mounted) return;

    if (result != null && result.isCompleted) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref.read(riderPackageProvider).error;
    SnackBarUtils.showError(
      context,
      error ??
          AppLocalization.translate(
            'payment_verification_failed',
            ref.read(appLanguageProvider),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final packageState = ref.watch(riderPackageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.translate('package_tier', lang)),
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade to ${widget.checkout.targetLabel}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'One-time payment: PHP ${widget.checkout.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 15),
                color: const Color(0xFF5F2D82),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              _openedBrowser
                  ? 'Complete payment in your browser, then return here and tap confirm.'
                  : 'Opening payment page...',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: packageState.isProcessing ? null : _confirmPayment,
                child: packageState.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalization.translate('i_completed_payment', lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
