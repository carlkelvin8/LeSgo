import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import 'rider_wallet_link_account_dialog.dart';

class RiderWalletWithdrawDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final double availableBalance;

  const RiderWalletWithdrawDialog({
    super.key,
    required this.parentContext,
    required this.availableBalance,
  });

  @override
  ConsumerState<RiderWalletWithdrawDialog> createState() =>
      _RiderWalletWithdrawDialogState();
}

class _RiderWalletWithdrawDialogState
    extends ConsumerState<RiderWalletWithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _method = 'gcash';
  bool _submitting = false;
  bool _loadingAccounts = true;
  List<Map<String, dynamic>> _linkedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedAccounts() async {
    await ref.read(riderWalletProvider.notifier).loadWallet();
    final accounts = ref.read(riderWalletProvider).linkedAccounts;
    if (!mounted) return;
    setState(() {
      _linkedAccounts = accounts;
      _loadingAccounts = false;
      if (_methodForProvider('gcash') != null) {
        _method = 'gcash';
      } else if (_methodForProvider('maya') != null) {
        _method = 'maya';
      }
    });
  }

  Map<String, dynamic>? _methodForProvider(String provider) {
    for (final account in _linkedAccounts) {
      if (account['provider']?.toString() != provider) continue;
      final meta = account['meta'];
      final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
      final hasNumber =
          metaMap['account_number']?.toString().isNotEmpty == true;
      final hasLast4 = account['account_last4']?.toString().isNotEmpty == true;
      if (hasNumber || hasLast4 || account['is_verified'] == true) {
        return account;
      }
    }
    return null;
  }

  bool get _hasLinkedPayoutAccount =>
      _methodForProvider('gcash') != null || _methodForProvider('maya') != null;

  Future<void> _linkAccount(String provider, String title) async {
    final linked = await showDialog<bool>(
      context: context,
      builder: (_) => RiderWalletLinkAccountDialog(
        parentContext: widget.parentContext,
        provider: provider,
        title: title,
      ),
    );
    if (linked == true) {
      await _loadLinkedAccounts();
    }
  }

  String? _validateAmount(String? value) {
    final lang = ref.read(appLanguageProvider);
    if (value == null || value.trim().isEmpty) {
      return AppLocalization.translate('please_enter_amount', lang);
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) return AppLocalization.translate('please_enter_valid_number', lang);
    if (amount < 10) return AppLocalization.translate('minimum_withdrawal_10', lang);
    final balance = ref.read(riderWalletProvider).balance;
    if (amount > balance) {
      return AppLocalization.translate('insufficient_balance', lang);
    }
    return null;
  }

  Future<void> _submit() async {
    if (_methodForProvider(_method) == null) {
      final lang = ref.read(appLanguageProvider);
      SnackBarUtils.showError(
        context,
        'Link your ${AppLocalization.translate(_method == 'gcash' ? 'gcash' : 'maya', lang)} account first.',
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final amount = double.parse(_amountController.text.trim());
    final success = await ref
        .read(riderWalletProvider.notifier)
        .withdraw(amount, _method);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        final lang = ref.read(appLanguageProvider);
      SnackBarUtils.showSuccess(
          widget.parentContext,
          AppLocalization.translate('amount_sent', lang)
              .replaceAll('{{amount}}', amount.toStringAsFixed(2))
              .replaceAll('{{provider}}', AppLocalization.translate(_method == 'gcash' ? 'gcash' : 'maya', lang)),
        );
      }
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? AppLocalization.translate('withdrawal_failed', ref.read(appLanguageProvider)),
      );
    }
  }

  Widget _linkedSummary(String provider, String label) {
    final account = _methodForProvider(provider);
    if (account == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontFamily: 'TT Fors')),
        subtitle: Text(
          AppLocalization.translate('not_linked', ref.read(appLanguageProvider)),
          style: TextStyle(fontFamily: 'TT Fors', color: Colors.orange),
        ),
        trailing: TextButton(
          onPressed: _submitting ? null : () => _linkAccount(provider, label),
          child: Text(AppLocalization.translate('link_account', ref.read(appLanguageProvider))),
        ),
      );
    }

    final meta = account['meta'];
    final number = meta is Map ? meta['account_number']?.toString() : null;
    final last4 = account['account_last4']?.toString();
    final display = number != null && number.length >= 4
        ? '•••• ${number.substring(number.length - 4)}'
        : (last4 != null ? '•••• $last4' : 'Linked');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontFamily: 'TT Fors')),
      subtitle: Text(
        display,
        style: TextStyle(fontFamily: 'TT Fors', color: Colors.grey.shade700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveBalance = ref.watch(riderWalletProvider).balance;

    final lang = ref.watch(appLanguageProvider);

    return AlertDialog(
      title: Text(
        AppLocalization.translate('withdraw_via_xendit', lang),
        style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.bold),
      ),
      content: _loadingAccounts
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available: PHP ${liveBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Funds are sent to your linked GCash or Maya using Xendit payouts.',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linkedSummary('gcash', AppLocalization.translate('gcash', lang)),
                    _linkedSummary('maya', AppLocalization.translate('maya', lang)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'gcash', label: Text(AppLocalization.translate('gcash', lang))),
                        ButtonSegment(value: 'maya', label: Text(AppLocalization.translate('maya', lang))),
                      ],
                      selected: {_method},
                      onSelectionChanged: _submitting
                          ? null
                          : (selection) {
                              setState(() => _method = selection.first);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppLocalization.translate('amount', lang),
                        prefixText: 'PHP ',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateAmount,
                      enabled: !_submitting && _hasLinkedPayoutAccount,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(AppLocalization.translate('cancel', lang)),
        ),
        ElevatedButton(
          onPressed: _submitting || !_hasLinkedPayoutAccount ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppLocalization.translate('withdraw', lang)),
        ),
      ],
    );
  }
}
