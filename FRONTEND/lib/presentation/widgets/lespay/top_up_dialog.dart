import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators/lespay_validator.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../../screens/main/lespay/xendit_payment_screen.dart';
import 'top_up_fee_summary.dart';

enum TopUpPurpose { topUp, qrPay }

class TopUpDialog extends ConsumerStatefulWidget {
  /// Scaffold context from LesPay screen (stays valid after dialog closes).
  final BuildContext parentContext;
  final TopUpPurpose purpose;

  const TopUpDialog({
    super.key,
    required this.parentContext,
    this.purpose = TopUpPurpose.topUp,
  });

  @override
  ConsumerState<TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends ConsumerState<TopUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  static const _quickAmounts = [100.0, 200.0, 500.0, 1000.0];
  String? _submitError;

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text.trim());
    final rootNav = Navigator.of(context, rootNavigator: true);
    setState(() => _submitError = null);

    final checkout = await ref.read(lespayProvider.notifier).startTopUp(amount);

    if (!mounted) return;

    if (checkout == null) {
      // A snackbar would sit behind this dialog, so show the failure inside it.
      final error = ref.read(lespayProvider).error;
      setState(() {
        _submitError = error ?? 'Could not start top-up. Please try again.';
      });
      return;
    }

    // Close dialog first, then open Xendit checkout on root navigator.
    rootNav.pop();

    final paid = await rootNav.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => XenditPaymentScreen(checkout: checkout),
      ),
    );

    if (paid == true) {
      ref.read(lespayProvider.notifier).refreshBalance();
      if (widget.parentContext.mounted) {
        SnackBarUtils.showSuccess(
          widget.parentContext,
          '${Money.format(amount)} added to your wallet!',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);

    return AlertDialog(
      title: Text(
        widget.purpose == TopUpPurpose.qrPay
            ? 'QR Pay (3% fee)'
            : 'Top Up (3% fee)',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.purpose == TopUpPurpose.qrPay
                  ? 'A 3% top-up fee applies. Pay the total below with QR Ph. '
                        'Scan the PayMongo QR code using GCash, Maya, or your banking app.'
                  : 'A 3% top-up fee applies. You pay the total below using your credit or debit card.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: AppColors.foreground(context, Colors.grey[700]!),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TextFormField(
              controller: _amountController,
              onChanged: (_) => setState(() => _submitError = null),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount to add to wallet',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              validator: LespayValidator.topUpAmount,
              enabled: !lespayState.isProcessingTopUp,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TopUpFeeSummary(walletAmount: _parsedAmount),
            if (_submitError != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                _submitError!,
                key: const Key('top_up_error'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: Colors.red.shade400,
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            // One even row of presets, so four amounts never wrap to a lonely
            // second line.
            Row(
              children: [
                for (var i = 0; i < _quickAmounts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          Money.format(_quickAmounts[i], decimals: 0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      selected:
                          _amountController.text ==
                          _quickAmounts[i].toStringAsFixed(0),
                      onSelected: lespayState.isProcessingTopUp
                          ? null
                          : (_) {
                              setState(() {
                                _submitError = null;
                                _amountController.text = _quickAmounts[i]
                                    .toStringAsFixed(0);
                              });
                            },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: lespayState.isProcessingTopUp
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: AppColors.foreground(context, Colors.grey[600]!),
              fontSize: ResponsiveUtils.fontSize(context, 14),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: lespayState.isProcessingTopUp ? null : _startTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonFill(context),
            foregroundColor: AppColors.onButton(context),
          ),
          child: lespayState.isProcessingTopUp
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Continue to payment',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
        ),
      ],
    );
  }
}
