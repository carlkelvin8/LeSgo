import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/routers/app_router.dart';
import '../../core/constants/routers/auth/auth_routes.dart';
import '../../core/constants/routers/main/main_routes.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../domain/entities/auth/registration_fee_status.dart';
import '../provider/auth/auth_provider.dart';
import '../provider/auth/registration_fee_provider.dart';
import '../provider/auth/rider_auth_provider.dart';

/// Shared registration-fee status + payment screen for rider & merchant.
///
/// Shows what is blocking the account (unpaid fee vs pending approval) and
/// lets the user pay via PayMongo or proceed once the account is active.
class RegistrationFeeScreen extends ConsumerStatefulWidget {
  final String targetMainRoute;

  const RegistrationFeeScreen({
    super.key,
    this.targetMainRoute = MainRoutes.riderMain,
  });

  @override
  ConsumerState<RegistrationFeeScreen> createState() =>
      _RegistrationFeeScreenState();
}

final registrationPaymentLauncherProvider = Provider<Future<bool> Function(Uri)>((ref) =>
    (uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

class _RegistrationFeeScreenState extends ConsumerState<RegistrationFeeScreen>
    with WidgetsBindingObserver {
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationFeeProvider.notifier).loadStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !ref.read(registrationFeeProvider).isProcessing) {
      ref.read(registrationFeeProvider.notifier).loadStatus(silent: true);
    }
  }

  Future<void> _payNow() async {
    if (_launching || ref.read(registrationFeeProvider).isProcessing) return;
    setState(() => _launching = true);
    try {
      final status = ref.read(registrationFeeProvider).status;
      final url = status?.isPendingPayment == true &&
              status?.checkoutUrl?.isNotEmpty == true
          ? status!.checkoutUrl
          : await ref.read(registrationFeeProvider.notifier).payNow();
      if (!mounted || url == null || url.isEmpty) return;
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Invalid payment URL');
      }
      final launched = await ref.read(registrationPaymentLauncherProvider)(uri);
      if (!launched) throw StateError('Payment page unavailable');
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(context,
            'Could not open payment. Your checkout is saved; use Resume Payment or Verify Payment.');
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _verifyAndRefresh() async {
    final verified = await ref.read(registrationFeeProvider.notifier).verifyPayment();
    if (!mounted) return;
    final feeState = ref.read(registrationFeeProvider);
    if (feeState.error != null) {
      SnackBarUtils.showError(context, feeState.error!);
      return;
    }
    final status = feeState.status;
    if (verified && status != null && status.isActive && status.shouldBeActive) {
      _enterApp();
    } else {
      SnackBarUtils.showInfo(
        context,
        status?.displayStatus ?? 'Payment verification completed.',
      );
    }
  }

  void _enterApp() {
    final feeState = ref.read(registrationFeeProvider);
    final status = feeState.status;
    if (feeState.isLoading || feeState.isProcessing || feeState.error != null ||
        status == null || !status.isActive || !status.shouldBeActive) {
      return;
    }
    ref.read(riderAuthProvider.notifier).applyRegistrationStatus(status);
    ref.read(registrationFeeProvider.notifier).clearError();
    if (ref.read(riderAuthProvider).isLoggedIn) {
      AppRouter.pushAndRemoveUntil(context, widget.targetMainRoute);
      return;
    }
    final user = ref.read(riderAuthProvider).user;
    final target = user != null && user.isMerchant
        ? AuthView.merchantLogin
        : AuthView.riderLogin;
    ref.read(authViewProvider.notifier).state = target;
    AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
  }

  Future<void> _logout() async {
    final user = ref.read(riderAuthProvider).user;
    await ref.read(riderAuthProvider.notifier).logout(ref);
    if (!mounted) return;
    final target = (user?.isMerchant == true || user?.isStaff == true)
        ? AuthView.merchantLogin
        : AuthView.riderLogin;
    ref.read(authViewProvider.notifier).state = target;
    AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final feeState = ref.watch(registrationFeeProvider);
    final status = feeState.status;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _logout(),
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
        ),
      ),
      body: SafeArea(
        child: _buildBody(feeState, status),
      ),
    );
  }

  Widget _buildBody(
    RegistrationFeeState feeState,
    RegistrationFeeStatus? status,
  ) {
    if (feeState.isLoading && status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.error_outline,
                size: 72, color: Color(0xFF5F2D82)),
            const SizedBox(height: 16),
            const Text(
              'Could not load your registration status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (feeState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                feeState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(registrationFeeProvider.notifier)
                  .loadStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Active — everything unlocked.
    if (status.isActive && status.shouldBeActive) {
      return _buildMessage(
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
        title: 'Account Active',
        message: status.displayStatus ?? 'Your account is now active.',
        actions: [
          FilledButton.icon(
            onPressed: _enterApp,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to App'),
          ),
        ],
      );
    }

    // Rejected.
    if (status.isRejected) {
      return _buildMessage(
        icon: Icons.cancel,
        color: const Color(0xFFD32F2F),
        title: 'Application Not Approved',
        message: status.displayStatus ??
            'Your application was not approved. Contact support for assistance.',
        actions: const [],
      );
    }

    // Fee satisfied, awaiting approval.
    if (status.awaitingApprovalAfterPayment) {
      return _buildMessage(
        icon: Icons.hourglass_top,
        color: const Color(0xFF5F2D82),
        title: 'Payment Received',
        message: status.displayStatus ??
            'Your payment is complete. You are now waiting for admin approval.',
        actions: [
          OutlinedButton.icon(
            onPressed: () => ref.read(registrationFeeProvider.notifier)
                .loadStatus(silent: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ],
      );
    }

    // Needs payment OR waiting on PayMongo confirmation.
    return _buildPaymentRequired(feeState, status);
  }

  Widget _buildPaymentRequired(RegistrationFeeState feeState, RegistrationFeeStatus status) {
    final needsPayment = status.needsPayment;
    final message = status.displayStatus ??
        'Complete your registration fee to start using the app.';

    final actions = <Widget>[
      if (needsPayment || status.isPendingPayment)
        FilledButton.icon(
          onPressed: feeState.isProcessing || _launching ? null : _payNow,
          icon: feeState.isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.payment),
          label: Text(status.isPendingPayment ? 'Resume Payment' : 'Pay Registration Fee'),
        ),
      if (status.paymongoCheckoutId?.isNotEmpty == true)
        OutlinedButton.icon(
          onPressed: feeState.isProcessing ? null : _verifyAndRefresh,
          icon: const Icon(Icons.verified_user),
          label: const Text('Verify Payment'),
        ),
      OutlinedButton.icon(
        onPressed: () =>
            ref.read(registrationFeeProvider.notifier).loadStatus(silent: true),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Status'),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0x1A5F2D82),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 44,
              color: Color(0xFF5F2D82),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Complete Registration',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (status.amountValue > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x145F2D82),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x335F2D82)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Registration Fee',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.amountLabel,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.billingPeriod == 'annual'
                        ? 'Annual partner registration'
                        : 'One-time rider registration',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          if (status.failureReason != null) ...[
            const SizedBox(height: 16),
            Text(
              'Previous payment result: ${status.failureReason}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 28),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(width: double.infinity, child: a),
            ),
          ),
          if (feeState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              feeState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(icon, size: 72, color: color),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(width: double.infinity, child: a),
            ),
          ),
        ],
      ),
    );
  }
}
