import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/lespay_topup_fee.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../screens/main/riderside/rider_wallet_payment_screen.dart';

class RiderTopUpDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const RiderTopUpDialog({super.key, required this.parentContext});

  @override
  ConsumerState<RiderTopUpDialog> createState() => _RiderTopUpDialogState();
}

class _RiderTopUpDialogState extends ConsumerState<RiderTopUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  static const _quickAmounts = [100.0, 200.0, 500.0, 1000.0];

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final lang = ref.read(appLanguageProvider);
    if (value == null || value.trim().isEmpty) {
      return AppLocalization.translate('please_enter_amount', lang);
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) return AppLocalization.translate('please_enter_valid_number', lang);
    if (amount < 10) return AppLocalization.translate('minimum_amount_10', lang);
    if (amount > 100000) return AppLocalization.translate('maximum_amount_100k', lang);
    return null;
  }

  Future<void> _startTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text.trim());
    final checkout =
        await ref.read(riderWalletProvider.notifier).startTopUp(amount);

    if (!mounted) return;

    if (checkout == null) {
      setState(() {});
      return;
    }

    final rootNav = Navigator.of(context, rootNavigator: true);
    rootNav.pop();

    final paid = await rootNav.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RiderWalletPaymentScreen(checkout: checkout),
      ),
    );

    if (paid == true) {
      await ref.read(riderWalletProvider.notifier).loadWallet();
      if (widget.parentContext.mounted) {
        final lang = ref.read(appLanguageProvider);
        SnackBarUtils.showSuccess(
          widget.parentContext,
          AppLocalization.translate('amount_added_lespay', lang).replaceAll('{{amount}}', amount.toStringAsFixed(2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final walletState = ref.watch(riderWalletProvider);
    final pricing = LespayTopupFee.calculate(_parsedAmount);

    return AlertDialog(
      title: Text(
        AppLocalization.translate('top_up_fee', lang),
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
              AppLocalization.translate('pay_with_gcash_maya', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TextFormField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalization.translate('amount_to_add', lang),
                prefixText: 'PHP ',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
              enabled: !walletState.isProcessingTopUp,
            ),
            if (walletState.error != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                walletState.error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.red.shade700,
                ),
              ),
            ],
            if (_parsedAmount >= 10) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 10)),
              Text(
                AppLocalization.translate('fee_percent', lang).replaceAll('{{amount}}', pricing.feeAmount.toStringAsFixed(2)),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                AppLocalization.translate('total_to_pay_amount', lang).replaceAll('{{amount}}', pricing.totalCharge.toStringAsFixed(2)),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F2D82),
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((value) {
                return ChoiceChip(
                  label: Text('PHP ${value.toStringAsFixed(0)}'),
                  selected:
                      _amountController.text == value.toStringAsFixed(0),
                  onSelected: walletState.isProcessingTopUp
                      ? null
                      : (_) {
                          setState(() {
                            _amountController.text =
                                value.toStringAsFixed(0);
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: walletState.isProcessingTopUp
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(AppLocalization.translate('cancel', lang)),
        ),
        ElevatedButton(
          onPressed: walletState.isProcessingTopUp ? null : _startTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: walletState.isProcessingTopUp
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppLocalization.translate('continue_to_payment', lang)),
        ),
      ],
    );
  }
}
