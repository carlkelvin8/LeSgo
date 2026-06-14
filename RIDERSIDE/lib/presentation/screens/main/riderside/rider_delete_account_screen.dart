import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/auth_navigation.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/auth/rider_auth_provider.dart';

class RiderDeleteAccountScreen extends ConsumerStatefulWidget {
  const RiderDeleteAccountScreen({super.key});

  @override
  ConsumerState<RiderDeleteAccountScreen> createState() =>
      _RiderDeleteAccountScreenState();
}

class _RiderDeleteAccountScreenState
    extends ConsumerState<RiderDeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _confirmed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_confirmed) {
      SnackBarUtils.showError(
        context,
        'Please confirm that you understand this action is permanent.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text(
          'This cannot be undone. Your profile, documents, and personal '
          'information will be removed. Complete active deliveries and empty '
          'your LesPay wallet before continuing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.deleteAccountPermanently(
        password: _passwordController.text,
        confirmation: _confirmationController.text.trim(),
        reason: _reasonController.text,
      );

      final target = await ref.read(riderAuthProvider.notifier).logout(ref);

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Your account has been permanently deleted.',
      );
      navigateToLoginAfterLogout(context, ref, target: target);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        ApiService.extractError(e).isNotEmpty
            ? ApiService.extractError(e)
            : 'Could not delete account. Check your password and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delete Account'),
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
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Permanent deletion removes your personal data and signs you out '
                  'immediately. You cannot recover this account or log in again.',
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
                    return 'Password is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Confirm password',
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
                controller: _confirmationController,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().toUpperCase() != 'DELETE') {
                    return 'Type DELETE to confirm';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
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
                  'I understand my account and personal data will be permanently deleted.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              FilledButton(
                onPressed: _isSubmitting ? null : _deleteAccount,
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
                    : const Text('Delete account permanently'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
