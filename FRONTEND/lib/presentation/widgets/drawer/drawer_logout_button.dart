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
        horizontal: ResponsiveUtils.spacing(context, 20),
        vertical: ResponsiveUtils.spacing(context, 10),
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
                  final errorMessage = e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  );
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
          backgroundColor: Colors.red.withValues(alpha: 0.08),
          foregroundColor: Colors.red.shade700,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'Log out',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 15),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
