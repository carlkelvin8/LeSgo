import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/auth_navigation.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

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
    FocusScope.of(context).unfocus();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(
          AppLocalization.translate('deactivate_account_question', lang),
        ),
        content: Text(
          AppLocalization.translate('deactivate_dialog_message', lang),
        ),
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
      SnackBarUtils.showSuccess(
        context,
        AppLocalization.translate('account_deactivated', lang),
      );
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
    String tr(String key) => AppLocalization.translate(key, lang);
    final dark = profileDark(context);
    const purple = Color(0xFF5F2D82);
    final accent = dark ? const Color(0xFFCFACED) : purple;
    final border = dark ? const Color(0xFF493B56) : const Color(0xFFE5DEEC);
    final canSubmit =
        !_isSubmitting && _confirmed && _passwordController.text.isNotEmpty;

    InputDecoration inputDecoration(String label) => InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: profileMuted(context), fontSize: 14),
      filled: true,
      fillColor: dark ? const Color(0xFF1B1525) : Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
      appBar: AppBar(
        title: Text(
          tr('deactivate_account'),
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
        foregroundColor: profileText(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            ResponsiveUtils.scrollBottomPaddingForKeyboard(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF2B203A) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF3E2C51)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.pause_circle_outline_rounded,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr('deactivate_break_title'),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 22,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: profileText(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('deactivating_signs_out'),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 14,
                              color: profileMuted(context),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfilePanel(
                      showBorder: false,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('deactivate_confirm_title'),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: profileText(context),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isSubmitting,
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              color: profileText(context),
                              fontSize: 15,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? tr('password_required')
                                : null,
                            decoration: inputDecoration(tr('confirm_password'))
                                .copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: tr(
                                      _obscurePassword
                                          ? 'show_password'
                                          : 'hide_password',
                                    ),
                                    color: profileMuted(context),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reasonController,
                            enabled: !_isSubmitting,
                            minLines: 3,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: profileText(context),
                              fontSize: 15,
                            ),
                            decoration: inputDecoration(tr('reason_optional')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _confirmed
                            ? (dark ? const Color(0xFF2B203A) : Colors.white)
                            : (dark ? const Color(0xFF241D30) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CheckboxListTile(
                        value: _confirmed,
                        onChanged: _isSubmitting
                            ? null
                            : (value) =>
                                  setState(() => _confirmed = value ?? false),
                        activeColor: purple,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          tr('i_understand_deactivate'),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 13,
                            height: 1.5,
                            color: profileText(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: canSubmit ? _deactivate : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB63845),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: dark
                            ? const Color(0xFF352D3F)
                            : const Color(0xFFE9E3EE),
                        disabledForegroundColor: dark
                            ? const Color(0xFFA99BB8)
                            : const Color(0xFF807489),
                        minimumSize: const Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
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
                              tr('deactivate_account'),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.maybePop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        minimumSize: const Size.fromHeight(40),
                        textStyle: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        tr('keep_my_account'),
                        textAlign: TextAlign.center,
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
