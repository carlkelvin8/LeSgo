import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/auth/auth_routes.dart';
import '../../provider/auth/auth_provider.dart';
import '../global/confirm_dialog.dart';

class DrawerLogoutButton extends ConsumerWidget {
  const DrawerLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 24),
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      child: ElevatedButton(
        onPressed: () {
          showConfirmDialog(
            context: context,
            title: 'Logout',
            message: 'Are you sure you want to logout?',
            confirmLabel: 'Logout',
            onConfirm: () async {
              try {
                final message = await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, message);
                }
              } catch (e) {
                if (context.mounted) {
                  final errorMessage = e.toString().replaceFirst('Exception: ', '');
                  SnackBarUtils.showError(context, errorMessage);
                }
              }
              if (!context.mounted) {
                return;
              }
              AppRouter.pushAndRemoveUntil(context, LoginRoutes.login);
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          'Logout',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
