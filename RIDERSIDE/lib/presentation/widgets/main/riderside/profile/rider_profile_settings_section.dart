import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/app_localization.dart';
import '../more/rider_more_components.dart';
import 'profile_action_tile.dart';

class RiderProfileSettingsSection extends ConsumerWidget {
  const RiderProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoreSectionHeading(title: t('settings_support')),

        // ── Settings card ──────────────────────────────────────────────
        MoreMenuGroup(
          children: [
            ProfileActionTile(
              icon: Icons.lock_outline_rounded,
              title: t('change_password'),
              subtitle: t('rp_password_hint'),

              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderChangePassword),
            ),
          ],
        ),

        const SizedBox(height: 24),

        MoreSectionHeading(title: t('rp_account_controls')),

        // ── Danger zone ────────────────────────────────────────────────
        MoreMenuGroup(
          children: [
            ProfileActionTile(
              icon: Icons.person_off_outlined,
              title: t('deactivate_account'),
              subtitle: t('rp_deactivate_hint'),

              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderDeactivateAccount),
            ),
            ProfileActionTile(
              icon: Icons.delete_outline_rounded,
              title: t('delete_account_permanently'),
              subtitle: t('rp_delete_hint'),
              destructive: true,
              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderDeleteAccount),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
