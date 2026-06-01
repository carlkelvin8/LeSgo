import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/utils.dart';
import '../../provider/register/register_payment_provider.dart';
import '../../widgets/widgets.dart';

class RegisterPaymentScreen extends ConsumerStatefulWidget {
  final RegisterPaymentRole role;

  const RegisterPaymentScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterPaymentScreen> createState() =>
      _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends ConsumerState<RegisterPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerPaymentProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              const HomeHeader(showBackButton: true),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              Text(
                'Registration Payment',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 22),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Pay the one-time registration fee via GCash to activate your account.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 32)),
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5F2D82).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount Due',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      'PHP ${AppConfig.registrationFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 32),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: state.isProcessing ? 'Processing...' : 'Pay via GCash',
                isLoading: state.isProcessing,
                onPressed: state.isProcessing ? null : _pay,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              TextButton(
                onPressed: state.isProcessing ? null : _skipToLogin,
                child: Text(
                  'Pay later — go to login',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    final success = await ref
        .read(registerPaymentProvider.notifier)
        .payRegistrationFee(widget.role);

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'Registration payment submitted!');
      _finish();
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(registerPaymentProvider).errorMessage ?? 'Payment failed',
      );
    }
  }

  void _skipToLogin() => _finish();

  void _finish() {
    ref.read(registerPaymentProvider.notifier).resetFlow();
    AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
  }
}
