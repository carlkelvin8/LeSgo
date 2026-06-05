import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../provider/auth/auth_provider.dart';

class DeactivateAccountScreen extends ConsumerStatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  ConsumerState<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends ConsumerState<DeactivateAccountScreen> {
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
    if (!_confirmed) {
      SnackBarUtils.showError(
        context,
        'Please confirm that you understand this action.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate account?'),
        content: const Text(
          'Your account will be deactivated and you will be signed out. '
          'Contact support if you need to reactivate later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await getIt<AuthRemoteDataSource>().deactivateAccount(
        password: _passwordController.text,
        reason: _reasonController.text,
      );

      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Your account has been deactivated.');
      AppRouter.pushAndRemoveUntil(context, LoginRoutes.login);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showErrorFrom(
        context,
        e,
        fallbackEn: 'Could not deactivate account. Check your password.',
        fallbackTl:
            'Hindi ma-deactivate ang account. Suriin ang password.',
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
        title: const Text('Deactivate Account'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
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
                  'Deactivating your account signs you out and limits access to '
                  'LeSGo services. You can contact support to request reactivation.',
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
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                  'I understand my account will be deactivated.',
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
                    : const Text('Deactivate account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
