import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/auth/rider_auth_provider.dart';

class RiderSecurityScreen extends ConsumerWidget {
  const RiderSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);
    final user = ref.watch(riderAuthProvider).user;
    final isMerchant = user?.isMerchant ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          AppLocalization.translate('security', lang),
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F2D82),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hp, 8, hp, 32),
        children: [
          Text(
            AppLocalization.translate('change_password_instructions', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _SecurityTile(
            icon: Icons.lock_outline,
            title: AppLocalization.translate('change_password', lang),
            onTap: () => AppRouter.push(context, MainRoutes.riderChangePassword),
          ),
          _SecurityTile(
            icon: Icons.badge_outlined,
            title: AppLocalization.translate('document_verification', lang),
            onTap: () => AppRouter.push(context, MainRoutes.riderDocuments),
          ),
          // Hide Deactivate and Delete options for Merchants
          if (!isMerchant) ...[
            _SecurityTile(
              icon: Icons.pause_circle_outline,
              title: AppLocalization.translate('deactivate_account', lang),
              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderDeactivateAccount),
            ),
            _SecurityTile(
              icon: Icons.delete_forever_outlined,
              title: AppLocalization.translate('delete_account', lang),
              onTap: () => AppRouter.push(context, MainRoutes.riderDeleteAccount),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.spacing(context, 10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF5F2D82).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF5F2D82)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}