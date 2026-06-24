import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderWalletLinkAccountDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final String provider;
  final String title;

  const RiderWalletLinkAccountDialog({
    super.key,
    required this.parentContext,
    required this.provider,
    required this.title,
  });

  @override
  ConsumerState<RiderWalletLinkAccountDialog> createState() =>
      _RiderWalletLinkAccountDialogState();
}

class _RiderWalletLinkAccountDialogState
    extends ConsumerState<RiderWalletLinkAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _submitting = false;
  bool _unlinking = false;

  @override
  void initState() {
    super.initState();
    final name = ref.read(riderAuthProvider).user?.name;
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    }
    _prefillLinkedAccount();
  }

  void _prefillLinkedAccount() {
    final wallet = ref.read(riderWalletProvider);
    for (final account in wallet.linkedAccounts) {
      if (account['provider']?.toString() != widget.provider) continue;
      final meta = account['meta'];
      if (meta is Map) {
        final number = meta['account_number']?.toString();
        if (number != null && number.isNotEmpty) {
          _phoneController.text = number;
        }
        final holder = meta['account_holder_name']?.toString();
        if (holder != null && holder.isNotEmpty) {
          _nameController.text = holder;
        }
      }
      break;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final lang = ref.read(appLanguageProvider);
    if (value == null || value.trim().isEmpty) {
      return AppLocalization.translate('enter_mobile_number', lang);
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 12) {
      return AppLocalization.translate('enter_valid_ph_mobile', lang);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final success = await ref.read(riderWalletProvider.notifier).linkAccount(
          provider: widget.provider,
          accountNumber: _phoneController.text.trim(),
          accountHolderName: _nameController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      if (widget.parentContext.mounted) {
        SnackBarUtils.showSuccess(
          widget.parentContext,
          '${AppLocalization.translate(widget.provider == 'gcash' ? 'gcash' : 'maya', ref.read(appLanguageProvider))} linked for Xendit withdrawals.',
        );
      }
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? AppLocalization.translate('could_not_link_account', ref.read(appLanguageProvider)),
      );
    }
  }

  Future<void> _unlink() async {
    setState(() => _unlinking = true);
    final success = await ref
        .read(riderWalletProvider.notifier)
        .unlinkAccount(widget.provider);

    if (!mounted) return;
    setState(() => _unlinking = false);

    if (success) {
      Navigator.of(context).pop(true);
      if (widget.parentContext.mounted) {
        SnackBarUtils.showSuccess(
          widget.parentContext,
          '${AppLocalization.translate(widget.provider == 'gcash' ? 'gcash' : 'maya', ref.read(appLanguageProvider))} account removed.',
        );
      }
    } else {
      final error = ref.read(riderWalletProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? AppLocalization.translate('could_not_remove_account', ref.read(appLanguageProvider)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final wallet = ref.watch(riderWalletProvider);
    final isLinked = wallet.isProviderLinked(widget.provider);
    final busy = _submitting || _unlinking;

    return AlertDialog(
      title: Text(
        isLinked
            ? AppLocalization.translate('manage_account', lang).replaceAll('{{provider}}', widget.title)
            : '${AppLocalization.translate('link_account', lang)} ${widget.title}',
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the ${widget.title} mobile number that will receive withdrawals via Xendit.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalization.translate('account_holder_name', lang),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppLocalization.translate('name_is_required', ref.read(appLanguageProvider)) : null,
              enabled: !busy,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${widget.title} mobile number',
                hintText: '09XXXXXXXXX',
                border: const OutlineInputBorder(),
              ),
              validator: _validatePhone,
              enabled: !busy,
            ),
          ],
        ),
      ),
      actions: [
        if (isLinked)
          TextButton(
            onPressed: busy ? null : _unlink,
            child: Text(
              AppLocalization.translate('unlink_account', lang),
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(AppLocalization.translate('cancel', lang)),
        ),
        ElevatedButton(
          onPressed: busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isLinked ? 'Update' : AppLocalization.translate('link_account', lang)),
        ),
      ],
    );
  }
}
