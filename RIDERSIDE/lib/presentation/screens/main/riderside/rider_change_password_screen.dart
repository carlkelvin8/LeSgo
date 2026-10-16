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
    if (_isSubmitting) return;
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
      SnackBarUtils.showSuccess(
        context,
        AppLocalization.translate('password_updated', lang),
      );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalization.translate('change_password', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.spacing(context, 20),
            ResponsiveUtils.spacing(context, 20),
            ResponsiveUtils.spacing(context, 20),
            ResponsiveUtils.scrollBottomPaddingForKeyboard(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFF2EBF7),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF5F2D82),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalization.translate(
                          'password_security_heading',
                          lang,
                        ),
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: Color(0xFF302638),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalization.translate(
                          'change_password_instructions',
                          lang,
                        ),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          height: 1.5,
                          color: const Color(0xFF766B7F),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      _passwordField(
                        controller: _currentController,
                        label: AppLocalization.translate(
                          'current_password',
                          lang,
                        ),
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      _passwordField(
                        controller: _newController,
                        label: AppLocalization.translate('new_password', lang),
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: LoginValidator.strongPassword,
                        isNewPassword: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalization.translate(
                          'password_requirements_hint',
                          lang,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF766B7F),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 22)),
                      _passwordField(
                        isNewPassword: true,
                        isLast: true,
                        controller: _confirmController,
                        label: AppLocalization.translate(
                          'confirm_new_password',
                          lang,
                        ),
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (value) {
                          if (value != _newController.text) {
                            return AppLocalization.translate(
                              'passwords_do_not_match',
                              lang,
                            );
                          }
                          return LoginValidator.strongPassword(value);
                        },
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2D82),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
                            : Text(
                                AppLocalization.translate(
                                  'change_password',
                                  lang,
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
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    bool isNewPassword = false,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF493C54),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          enabled: !_isSubmitting,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: [
            isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
          ],
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: isLast ? (_) => _submit() : null,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 15,
            color: Color(0xFF302638),
          ),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) return '$label is required';
                return null;
              },
          decoration: InputDecoration(
            hintText: AppLocalization.translate(
              'password_field_hint',
              ref.read(appLanguageProvider),
            ),
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9A90A3)),
            filled: true,
            fillColor: const Color(0xFFFCFAFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1D9E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6D3EA0),
                width: 1.5,
              ),
            ),
            errorMaxLines: 3,
            suffixIcon: IconButton(
              tooltip: AppLocalization.translate(
                obscure ? 'show_password' : 'hide_password',
                ref.read(appLanguageProvider),
              ),
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 21,
                color: const Color(0xFF82758D),
              ),
              onPressed: _isSubmitting ? null : onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
