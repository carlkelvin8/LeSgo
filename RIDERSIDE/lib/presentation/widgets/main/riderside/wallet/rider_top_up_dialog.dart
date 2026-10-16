import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/lespay_topup_fee.dart';
import 'package:flutter/services.dart';
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
    if (amount == null || !amount.isFinite) {
      return AppLocalization.translate('please_enter_valid_number', lang);
    }
    if (amount < 10) {
      return AppLocalization.translate('minimum_amount_10', lang);
    }
    if (amount > 100000) {
      return AppLocalization.translate('maximum_amount_100k', lang);
    }
    return null;
  }

  Future<void> _startTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text.trim());
    final lang = ref.read(appLanguageProvider);
    final parentContext = widget.parentContext;
    final notifier = ref.read(riderWalletProvider.notifier);
    final checkout = await notifier.startTopUp(amount);

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

    if (!parentContext.mounted) return;

    // Always refresh on return so the balance reflects even when the rider
    // paid in the browser and did not tap "I completed payment".
    await notifier.loadWallet();

    if (paid == true) {
      if (!parentContext.mounted) return;
      SnackBarUtils.showSuccess(
        parentContext,
        AppLocalization.translate(
          'amount_added_lespay',
          lang,
        ).replaceAll('{{amount}}', amount.toStringAsFixed(2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final walletState = ref.watch(riderWalletProvider);
    final busy = walletState.isProcessingTopUp;
    final valid =
        _parsedAmount.isFinite &&
        _parsedAmount >= 10 &&
        _parsedAmount <= 100000;
    final pricing = LespayTopupFee.calculate(valid ? _parsedAmount : 0);
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final purple = dark ? const Color(0xFFD8B6F4) : const Color(0xFF5F2D82);
    final tint = dark ? const Color(0xFF302239) : const Color(0xFFF7F2FB);
    String tr(String key) => AppLocalization.translate(key, lang);

    Widget summaryRow(String label, double amount, {bool total = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: total ? colors.onSurface : colors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: total ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                valid ? '₱${amount.toStringAsFixed(2)}' : '—',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: total ? 18 : 13,
                  fontWeight: FontWeight.w700,
                  color: total ? purple : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: dark ? colors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontFamily: 'TT Fors', color: colors.onSurface),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LesPay',
                                style: TextStyle(
                                  color: purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                tr('top_up'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: tr('cancel'),
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('pay_with_gcash_maya'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('amount_to_add'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) =>
                              RegExp(
                                r'^\d{0,6}(\.\d{0,2})?$',
                              ).hasMatch(newValue.text)
                              ? newValue
                              : oldValue,
                        ),
                      ],
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: purple,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 18, right: 10),
                          child: Text(
                            '₱',
                            style: TextStyle(fontSize: 28, color: purple),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                        ),
                        filled: true,
                        fillColor: tint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: purple.withValues(alpha: 0.14),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: purple, width: 2),
                        ),
                        errorMaxLines: 3,
                      ),
                      validator: _validateAmount,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 340 &&
                                MediaQuery.textScalerOf(context).scale(1) < 1.4
                            ? 4
                            : 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickAmounts.map((value) {
                            final selected = _parsedAmount == value;
                            return SizedBox(
                              width:
                                  (constraints.maxWidth - (columns - 1) * 8) /
                                  columns,
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                        _amountController.text = value
                                            .toStringAsFixed(0);
                                        _formKey.currentState?.validate();
                                      }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: selected
                                      ? purple
                                      : colors.onSurface,
                                  backgroundColor: selected
                                      ? tint
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: selected
                                        ? purple
                                        : colors.outlineVariant,
                                    width: selected ? 1.5 : 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  '₱${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          summaryRow(tr('lespay_credit'), pricing.walletAmount),
                          summaryRow(
                            tr('top_up_fee_percent'),
                            pricing.feeAmount,
                          ),
                          Divider(
                            height: 20,
                            color: purple.withValues(alpha: 0.12),
                          ),
                          summaryRow(
                            tr('total_to_pay'),
                            pricing.totalCharge,
                            total: true,
                          ),
                        ],
                      ),
                    ),
                    if (walletState.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        walletState.error!,
                        style: TextStyle(color: colors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : _startTopUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5F2D82),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr('continue_to_payment'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
