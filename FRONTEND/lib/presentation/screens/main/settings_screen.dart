import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/app_localization.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../../provider/theme_provider.dart';

const _brand = Color(0xFF5F2D82);
const _red = Color(0xFFB8293B);
const _canvas = Color(0xFFF8F6FA);
const _outline = Color(0xFFE9E2F0);
const _text = Color(0xFF231831);
const _muted = Color(0xFF6D6279);
const _font = 'Sora';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final language = ref.watch(appLanguageProvider);
    String label(String key) => AppLocalization.translate(key, language);
    void go(String route) => AppRouter.push(context, route);

    return Scaffold(
      backgroundColor: AppColors.surface(context, _canvas),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, _canvas),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Center(
            child: IconButton.outlined(
              tooltip: label('back'),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.foreground(context, _text),
                side: BorderSide(color: AppColors.border(context, _outline)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),
        title: Text(
          label('settings'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            color: AppColors.foreground(context, _text),
            fontFamily: _font,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              MediaQuery.paddingOf(context).bottom + 28,
            ),
            children: [
              _ProfileCard(
                editLabel: label('edit_profile'),
                fallbackName: label('my_profile'),
                onTap: () => go(MainRoutes.profile),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Shortcut(
                      icon: Icons.receipt_long_rounded,
                      label: label('orders_shortcut'),
                      tint: const Color(0xFF673489),
                      onTap: () => go(MainRoutes.orderHistory),
                    ),
                    const SizedBox(width: 8),
                    _Shortcut(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'LesPay',
                      tint: const Color(0xFF186458),
                      onTap: () => go(MainRoutes.lespay),
                    ),
                    const SizedBox(width: 8),
                    _Shortcut(
                      icon: Icons.favorite_border_rounded,
                      label: label('favorites'),
                      tint: const Color(0xFF9A3F69),
                      onTap: () => go(MainRoutes.favorites),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _Group(
                title: label('account'),
                rows: [
                  _Row(
                    icon: Icons.location_on_outlined,
                    title: label('saved_addresses'),
                    onTap: () => go(MainRoutes.addressManagement),
                  ),
                  _Row(
                    icon: Icons.shield_outlined,
                    title: label('security'),
                    onTap: () => go(MainRoutes.securitySettings),
                  ),
                  _Row(
                    icon: Icons.lock_outline_rounded,
                    title: label('change_password'),
                    onTap: () => go(MainRoutes.changePassword),
                  ),
                  _Row(
                    icon: Icons.badge_outlined,
                    title: label('document_verification'),
                    onTap: () => go(MainRoutes.documentVerification),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Group(
                title: label('settings_preferences'),
                rows: [
                  _Row(
                    icon: Icons.notifications_none_rounded,
                    title: label('notification_settings'),
                    onTap: () => go(MainRoutes.notificationSettings),
                  ),
                  _Row(
                    icon: Icons.language_rounded,
                    title: label('language'),
                    value: label(
                      language == AppLanguage.filipino ? 'filipino' : 'english',
                    ),
                    onTap: () => go(MainRoutes.languageSettings),
                  ),
                  _Row(
                    icon: Icons.dark_mode_outlined,
                    title: label('dark_mode'),
                    trailing: Switch(
                      value: isDark,
                      activeTrackColor: AppColors.accent(context, _brand),
                      activeThumbColor: AppColors.onAccent(context),
                      onChanged: (value) => ref
                          .read(themeModeProvider.notifier)
                          .setDarkMode(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Group(
                title: label('support'),
                featured: _SupportLink(
                  title: label('lesgo_support'),
                  onTap: () => go(MainRoutes.customerServiceChat),
                ),
                rows: [
                  _Row(
                    icon: Icons.confirmation_number_outlined,
                    title: label('support_tickets'),
                    onTap: () => go(MainRoutes.supportTickets),
                  ),
                  _Row(
                    icon: Icons.help_outline_rounded,
                    title: label('faqs'),
                    onTap: () => go(MainRoutes.faqs),
                  ),
                  _Row(
                    icon: Icons.info_outline_rounded,
                    title: label('about'),
                    value: AppInfo.version,
                    onTap: () => go(MainRoutes.about),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Group(
                title: label('account_management'),
                rows: [
                  _Row(
                    destructive: true,
                    icon: Icons.person_off_outlined,
                    title: label('deactivate_account'),
                    onTap: () => go(MainRoutes.deactivateAccount),
                  ),
                  _Row(
                    destructive: true,
                    icon: Icons.delete_outline_rounded,
                    title: label('delete_account'),
                    onTap: () => go(MainRoutes.deleteAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.editLabel,
    required this.fallbackName,
    required this.onTap,
  });

  final String editLabel;
  final String fallbackName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final name = profile.name.trim().isEmpty
        ? fallbackName
        : profile.name.trim();
    final photo = profile.profileImageUrl;
    final hasImage = photo != null && photo.isNotEmpty;

    return Material(
      color: const Color(0xFF2C153D),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF271334), Color(0xFF44205E), Color(0xFF693F85)],
            stops: [0, .62, 1],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              const PositionedDirectional(
                end: -70,
                top: -120,
                child: IgnorePointer(child: _ProfileOrnament()),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFAA87C3),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFF0DDF8),
                        foregroundImage: hasImage ? NetworkImage(photo) : null,
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: _font,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Color(0xFF482262),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w700,
                        fontSize: 25,
                        height: 1.15,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    if (profile.email.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        profile.email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: Color(0xFFEBDDFA),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A396D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              editLabel,
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOrnament extends StatelessWidget {
  const _ProfileOrnament();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 290,
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (final size in [290.0, 246.0, 202.0, 158.0])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x36DDC1FA)),
              color: const Color(0x09DDC1FA),
            ),
          ),
      ],
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? scheme.primary
        : tint;
    final radius = BorderRadius.circular(19);
    return Expanded(
      child: Material(
        color: AppColors.surface(context, Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.border(context, _outline)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: .10),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground(context, _text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    return Material(
      color: accent.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: AppColors.onAccent(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground(context, _text),
                  ),
                ),
              ),
              Icon(Icons.arrow_outward_rounded, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, this.featured, required this.rows});

  final String title;
  final Widget? featured;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border(context, _outline);
    final radius = BorderRadius.circular(20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 3, bottom: 9),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 16,
              letterSpacing: -.35,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, _text),
            ),
          ),
        ),
        if (featured != null) ...[featured!, const SizedBox(height: 8)],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 14,
                      color: border,
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.error
              : _red)
        : AppColors.accent(context, _brand);
    final ink = destructive ? accent : AppColors.foreground(context, _text);
    final muted = AppColors.foreground(context, _muted);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      value!,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing ??
                (destructive
                    ? const SizedBox.shrink()
                    : Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: muted,
                      )),
          ],
        ),
      ),
    );
  }
}
