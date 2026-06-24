import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/token_refresh_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators/login_validator.dart';

class RiderChangePasswordScreen extends ConsumerStatefulWidget {
  const RiderChangePasswordScreen({super.key});

  @override
  ConsumerState<RiderChangePasswordScreen> createState() =>
      _RiderChangePasswordScreenState();
}

class _RiderChangePasswordScreenState
    extends ConsumerState<RiderChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = ref.read(appLanguageProvider);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.changePassword(
        currentPassword: _currentController.text,
        password: _newController.text,
      );

      await TokenRefreshService.instance.persistAuthTokens(response);

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, AppLocalization.translate('password_updated', lang));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        ApiService.extractError(e).isNotEmpty
            ? ApiService.extractError(e)
            : AppLocalization.translate('could_not_change_password', lang),
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
        title: Text(AppLocalization.translate('change_password', lang)),
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
              Text(
                AppLocalization.translate('change_password_instructions', lang),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              _passwordField(
                controller: _currentController,
                label: AppLocalization.translate('current_password', lang),
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              _passwordField(
                controller: _newController,
                label: AppLocalization.translate('new_password', lang),
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: LoginValidator.strongPassword,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              _passwordField(
                controller: _confirmController,
                label: AppLocalization.translate('confirm_new_password', lang),
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newController.text) {
                    return AppLocalization.translate('passwords_do_not_match', lang);
                  }
                  return LoginValidator.strongPassword(value);
                },
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 32)),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
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
                    : Text(AppLocalization.translate('change_password', lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
