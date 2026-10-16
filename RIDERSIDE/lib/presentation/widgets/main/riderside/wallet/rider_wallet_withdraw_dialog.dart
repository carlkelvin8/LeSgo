import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  List<Map<String, dynamic>> _linkedAccounts = [];

  @override
  void initState() {
    super.initState();
    // Read whatever is already in state — no blocking load
    final accounts = ref.read(riderWalletProvider).linkedAccounts;
    _linkedAccounts = accounts;
    if (_methodForProvider('gcash') != null) {
      _method = 'gcash';
    } else if (_methodForProvider('maya') != null) {
      _method = 'maya';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _methodForProvider(String provider) {
    for (final account in _linkedAccounts) {
      if (account['provider']?.toString() != provider) continue;
      final meta = account['meta'];
      final metaMap = meta is Map
          ? Map<String, dynamic>.from(meta)
          : <String, dynamic>{};
      final hasNumber =
          metaMap['account_number']?.toString().isNotEmpty == true;
      final hasLast4 = account['account_last4']?.toString().isNotEmpty == true;
      if (hasNumber || hasLast4 || account['is_verified'] == true) {
        return account;
      }
    }
    return null;
  }

  Future<void> _linkAccount(String provider, String title) async {
    final linked = await showDialog<bool>(
      context: context,
      builder: (_) => RiderWalletLinkAccountDialog(
        parentContext: widget.parentContext,
        provider: provider,
        title: title,
      ),
    );
    if (linked == true && mounted) {
      final accounts = ref.read(riderWalletProvider).linkedAccounts;
      setState(() {
        _linkedAccounts = accounts;
        _method = provider;
      });
    }
  }

  String? _validateAmount(String? value) {
    final lang = ref.read(appLanguageProvider);
    if (value == null || value.trim().isEmpty) {
      return AppLocalization.translate('please_enter_amount', lang);
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return AppLocalization.translate('please_enter_valid_number', lang);
    }
    if (amount < 10) {
      return AppLocalization.translate('minimum_withdrawal_10', lang);
    }
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
              .replaceAll(
                '{{provider}}',
                AppLocalization.translate(
                  _method == 'gcash' ? 'gcash' : 'maya',
                  lang,
                ),
              ),
        );
      }
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ??
            AppLocalization.translate(
              'withdrawal_failed',
              ref.read(appLanguageProvider),
            ),
      );
    }
  }

  Widget _linkedSummary(String provider, String label) {
    final account = _methodForProvider(provider);
    final selected = _method == provider;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final meta = account?['meta'];
    final number = meta is Map ? meta['account_number']?.toString() : null;
    final last4 = account?['account_last4']?.toString();
    final display = account == null
        ? AppLocalization.translate('not_linked', ref.read(appLanguageProvider))
        : number != null && number.length >= 4
        ? '•••• ${number.substring(number.length - 4)}'
        : last4 != null
        ? '•••• $last4'
        : 'Linked';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? (dark ? const Color(0xFF352740) : const Color(0xFFF8F4FC))
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? const Color(0xFF8356A4)
                : dark
                ? const Color(0xFF51465B)
                : const Color(0xFFE6E0EC),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _submitting ? null : () => setState(() => _method = provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _providerLogo(provider, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? const Color(0xFFC9BDCF)
                              : const Color(0xFF766B7F),
                        ),
                      ),
                    ],
                  ),
                ),
                if (account == null)
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => _linkAccount(provider, label),
                    child: Text(
                      AppLocalization.translate(
                        'link_account',
                        ref.read(appLanguageProvider),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? const Color(0xFF8356A4)
                        : const Color(0xFF9D93A5),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveBalance = ref.watch(riderWalletProvider).balance;
    final lang = ref.watch(appLanguageProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final linked = _methodForProvider(_method) != null;
    final muted = dark ? const Color(0xFFC9BDCF) : const Color(0xFF766B7F);
    String t(String key) => AppLocalization.translate(key, lang);

    return AlertDialog(
      backgroundColor: dark ? const Color(0xFF241D2C) : Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      title: Row(
        children: [
          Expanded(
            child: Text(
              t('withdraw'),
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: t('cancel'),
            onPressed: _submitting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: muted, size: 22),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Transfer to your linked GCash or Maya account.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF302637)
                        : const Color(0xFFF7F5FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available to withdraw',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PHP ${liveBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Send to',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _linkedSummary('gcash', t('gcash')),
                _linkedSummary('maya', t('maya')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: t('amount'),
                    hintText: '0.00',
                    prefixText: 'PHP  ',
                    prefixStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                    filled: true,
                    fillColor: dark
                        ? const Color(0xFF302637)
                        : const Color(0xFFFCFAFD),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCD3E5)),
                    ),
                  ),
                  validator: _validateAmount,
                  enabled: !_submitting && linked,
                ),
                const SizedBox(height: 8),
                Text(
                  linked
                      ? t('minimum_withdrawal_10')
                      : 'Link the selected account to continue.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transfers are processed via PayMongo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting || !linked || liveBalance < 10
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t('withdraw'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _providerLogo(String provider, {double size = 34}) {
    return SvgPicture.asset(
      provider == 'gcash'
          ? 'assets/images/wallet/Gcash.svg'
          : 'assets/images/wallet/Maya.svg',
      width: size,
      height: size,
    );
  }
}
