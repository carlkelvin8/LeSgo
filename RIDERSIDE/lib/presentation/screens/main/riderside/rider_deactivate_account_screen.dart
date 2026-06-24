import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/auth_navigation.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/auth/rider_auth_provider.dart';

class RiderDeactivateAccountScreen extends ConsumerStatefulWidget {
  const RiderDeactivateAccountScreen({super.key});

  @override
  ConsumerState<RiderDeactivateAccountScreen> createState() =>
      _RiderDeactivateAccountScreenState();
}

class _RiderDeactivateAccountScreenState
    extends ConsumerState<RiderDeactivateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _confirmed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _deactivate() async {
    final lang = ref.read(appLanguageProvider);
    if (!_confirmed) {
      SnackBarUtils.showError(
        context,
        AppLocalization.translate('confirm_understand_action', lang),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.translate('deactivate_account_question', lang)),
        content: Text(AppLocalization.translate('deactivate_dialog_message', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.translate('cancel', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalization.translate('deactivate', lang)),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.deactivateAccount(
        password: _passwordController.text,
        reason: _reasonController.text,
      );

      final target = await ref.read(riderAuthProvider.notifier).logout(ref);

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, AppLocalization.translate('account_deactivated', lang));
      navigateToLoginAfterLogout(context, ref, target: target);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        ApiService.extractError(e).isNotEmpty
            ? ApiService.extractError(e)
            : AppLocalization.translate('could_not_deactivate', lang),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalization.translate('deactivate_account', lang)),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spacing(context, 20),
          ResponsiveUtils.spacing(context, 20),
          ResponsiveUtils.spacing(context, 20),
          ResponsiveUtils.scrollBottomPaddingForKeyboard(context),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  AppLocalization.translate('deactivating_signs_out', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: Colors.red[900],
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalization.translate('password_required', lang);
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: AppLocalization.translate('confirm_password', lang),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppLocalization.translate('reason_optional', lang),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              CheckboxListTile(
                value: _confirmed,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _confirmed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppLocalization.translate('i_understand_deactivate', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              FilledButton(
                onPressed: _isSubmitting ? null : _deactivate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalization.translate('deactivate_account', lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
