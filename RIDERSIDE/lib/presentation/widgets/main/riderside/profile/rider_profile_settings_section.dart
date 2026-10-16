import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/app_localization.dart';
import '../more/rider_more_components.dart';
import 'profile_panel.dart';

class RiderProfileSettingsSection extends ConsumerWidget {
  const RiderProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);
    final isDark = profileDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoreSectionHeading(title: t('settings_support')),

        // ── Settings card ──────────────────────────────────────────────
        _AnimatedMenuGroup(
          children: [
            _SpringTile(
              icon: Icons.lock_outline_rounded,
              title: t('change_password'),
              subtitle: t('rp_password_hint'),
              accent: const Color(0xFF317B9C),
              isDark: isDark,
              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderChangePassword),
            ),
            _SpringTile(
              icon: Icons.shield_outlined,
              title: t('security'),
              subtitle: t('rp_security_hint'),
              accent: const Color(0xFF187C69),
              isDark: isDark,
              onTap: () => AppRouter.push(context, MainRoutes.riderSecurity),
            ),
          ],
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        MoreSectionHeading(title: t('rp_account_controls')),

        // ── Danger zone ────────────────────────────────────────────────
        _AnimatedMenuGroup(
          isDark: isDark,
          isDanger: true,
          children: [
            _SpringTile(
              icon: Icons.person_off_outlined,
              title: t('deactivate_account'),
              subtitle: t('rp_deactivate_hint'),
              accent: const Color(0xFFAB5B3E),
              isDark: isDark,
              onTap: () =>
                  AppRouter.push(context, MainRoutes.riderDeactivateAccount),
            ),
            _SpringTile(
              icon: Icons.delete_outline_rounded,
              title: t('delete_account_permanently'),
              subtitle: t('rp_delete_hint'),
              accent: Colors.red.shade600,
              isDark: isDark,
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

// ─── Animated menu group ──────────────────────────────────────────────────────
class _AnimatedMenuGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final bool isDanger;

  const _AnimatedMenuGroup({
    required this.children,
    required this.isDark,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDanger
            ? (isDark ? const Color(0xFF200F0F) : const Color(0xFFFFF8F8))
            : (isDark ? const Color(0xFF1E1730) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDanger
              ? Colors.red.withValues(alpha: isDark ? .18 : .12)
              : (isDark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2)),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDanger ? Colors.red : const Color(0xFF5F2D82))
                .withValues(alpha: isDark ? .08 : .04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 64),
                  color: isDanger
                      ? Colors.red.withValues(alpha: isDark ? .12 : .08)
                      : (isDark
                          ? const Color(0xFF2E2540)
                          : const Color(0xFFF0EBF6)),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Spring tile ──────────────────────────────────────────────────────────────
class _SpringTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _SpringTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SpringTile> createState() => _SpringTileState();
}

class _SpringTileState extends State<_SpringTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 90),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: .97)
      .animate(CurvedAnimation(parent: _press, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    HapticFeedback.selectionClick();
    await _press.forward();
    await _press.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: InkWell(
        onTap: _onTap,
        onTapDown: (_) => _press.forward(),
        onTapCancel: () => _press.reverse(),
        splashColor: widget.accent.withValues(alpha: .08),
        highlightColor: widget.accent.withValues(alpha: .05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(
                      alpha: widget.isDark ? .18 : .09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: .20),
                    width: .8,
                  ),
                ),
                child: Icon(widget.icon, size: 17, color: widget.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? const Color(0xFFF5F0FB)
                            : const Color(0xFF1A0A2E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        color: widget.isDark
                            ? const Color(0xFF9A85B8)
                            : const Color(0xFFAA90C0),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: widget.isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFCCB0E0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
