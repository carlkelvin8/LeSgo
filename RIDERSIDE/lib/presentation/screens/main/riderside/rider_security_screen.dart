import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../widgets/common/settings_page_kit.dart';

class RiderSecurityScreen extends ConsumerWidget {
  const RiderSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);
    final hp = ResponsiveUtils.horizontalPadding(context);
    final user = ref.watch(riderAuthProvider).user;
    final isMerchant = user?.isMerchant ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SettingsKit.appBar(context, '', backgroundColor: Colors.white),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
        children: [
          Text(
            t('security'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 28),
              fontWeight: FontWeight.w800,
              color: SettingsKit.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('security_header_subtitle'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              height: 1.4,
              color: SettingsKit.muted,
            ),
          ),
          const SizedBox(height: 28),
          SettingsSectionLabel(t('security_section_protection')),
          _SecurityGroup(
            tiles: [
              _SecurityTile(
                icon: Icons.lock_outline_rounded,
                title: t('change_password'),
                subtitle: t('change_password_hint'),
                onTap: () =>
                    AppRouter.push(context, MainRoutes.riderChangePassword),
              ),
              _SecurityTile(
                icon: Icons.badge_outlined,
                title: t('document_verification'),
                subtitle: t('document_verification_hint'),
                onTap: () => AppRouter.push(context, MainRoutes.riderDocuments),
              ),
            ],
          ),
          // Hide Deactivate and Delete options for Merchants
          if (!isMerchant) ...[
            const SizedBox(height: 24),
            SettingsSectionLabel(
              t('security_section_danger'),
              color: SettingsKit.danger,
            ),
            _SecurityGroup(
              tiles: [
                _SecurityTile(
                  icon: Icons.pause_circle_outline_rounded,
                  title: t('deactivate_account'),
                  subtitle: t('deactivate_account_hint'),
                  destructive: true,
                  onTap: () => AppRouter.push(
                    context,
                    MainRoutes.riderDeactivateAccount,
                  ),
                ),
                _SecurityTile(
                  icon: Icons.delete_forever_outlined,
                  title: t('delete_account'),
                  subtitle: t('delete_account_hint'),
                  destructive: true,
                  onTap: () =>
                      AppRouter.push(context, MainRoutes.riderDeleteAccount),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          tiles[i],
        ],
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? SettingsKit.danger : SettingsKit.brand;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          // No side padding so icons line up with the page heading.
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: destructive
                            ? SettingsKit.danger
                            : SettingsKit.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        height: 1.35,
                        color: SettingsKit.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
