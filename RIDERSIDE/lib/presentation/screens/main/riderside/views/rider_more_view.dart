import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/theme_provider.dart';
import '../../../../widgets/main/riderside/more/rider_more_components.dart';
import '../rider_language_screen.dart';
import '../rider_package_tier_screen.dart';
import 'rider_mission_view.dart';
import 'rider_wallet_view.dart';

class RiderMoreView extends ConsumerStatefulWidget {
  const RiderMoreView({super.key});

  @override
  ConsumerState<RiderMoreView> createState() => _RiderMoreViewState();
}

class _RiderMoreViewState extends ConsumerState<RiderMoreView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final animation = _entrance.drive(
      CurveTween(
        curve: Interval(
          (index * .10).clamp(0.0, .55),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, .05), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  void _openSubScreen({required String title, required Widget body}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    String t(String key) => AppLocalization.translate(key, lang);

    return ColoredBox(
      color: dark ? const Color(0xFF171320) : const Color(0xFFF8F7FB),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          key: const PageStorageKey('rider-more-scroll'),
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 360 ? 16 : 24,
            24,
            constraints.maxWidth < 360 ? 16 : 24,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reveal(
                    0,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('more'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.9,
                            color: dark
                                ? Colors.white
                                : const Color(0xFF2A193A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('more_intro'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: dark
                                ? const Color(0xFFB9B1C6)
                                : const Color(0xFF756C80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _reveal(
                    1,
                    MoreWalletCard(
                      title: t('wallet'),
                      subtitle: t('more_wallet_subtitle'),
                      action: t('more_open_wallet'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RiderWalletScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reveal(
                    2,
                    LayoutBuilder(
                      builder: (context, size) {
                        final cards = [
                          MoreShortcutCard(
                            icon: Icons.payments_outlined,
                            title: t('earnings'),
                            subtitle: t('more_earnings_subtitle'),
                            accent: const Color(0xFF187C69),
                            onTap: () => AppRouter.push(
                              context,
                              MainRoutes.riderEarnings,
                            ),
                          ),
                          MoreShortcutCard(
                            icon: Icons.insights_rounded,
                            title: t('more_insights'),
                            subtitle: t('more_insights_subtitle'),
                            accent: const Color(0xFF6D3EA0),
                            onTap: () => AppRouter.push(
                              context,
                              MainRoutes.riderEarningsInsights,
                            ),
                          ),
                        ];
                        // Stack at large text sizes so translated labels can wrap.
                        if (size.maxWidth < 290 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              cards[0],
                              const SizedBox(height: 12),
                              cards[1],
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 12),
                              Expanded(child: cards[1]),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 26),
                  _reveal(
                    3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MoreSectionHeading(title: t('work_section')),
                        MoreMenuGroup(
                          children: [
                            MoreMenuRow(
                              icon: Icons.auto_awesome_outlined,
                              title: t('missions'),
                              subtitle: t('more_missions_subtitle'),
                              accent: const Color(0xFFA96B12),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RiderMissionView(
                                    includeBottomNavPadding: false,
                                  ),
                                ),
                              ),
                            ),
                            MoreMenuRow(
                              icon: Icons.star_outline_rounded,
                              title: t('my_rating'),
                              subtitle: t('more_rating_subtitle'),
                              accent: const Color(0xFFB3546C),
                              onTap: () => AppRouter.push(
                                context,
                                MainRoutes.riderRating,
                              ),
                            ),
                            MoreMenuRow(
                              icon: Icons.two_wheeler_outlined,
                              title: t('my_vehicles'),
                              subtitle: t('more_vehicles_subtitle'),
                              accent: const Color(0xFF317B9C),
                              onTap: () => AppRouter.push(
                                context,
                                MainRoutes.riderVehicleManagement,
                              ),
                            ),
                            MoreMenuRow(
                              icon: Icons.schedule_rounded,
                              title: t('scheduled_availability'),
                              subtitle: t('more_schedule_subtitle'),
                              onTap: () => AppRouter.push(
                                context,
                                MainRoutes.riderSchedule,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _reveal(
                    4,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MoreSectionHeading(title: t('settings')),
                        MoreMenuGroup(
                          children: [
                            MoreMenuRow(
                              icon: dark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              title: t('more_dark_mode'),
                              subtitle: t('more_dark_subtitle'),
                              trailing: Switch.adaptive(
                                value: themeMode == ThemeMode.dark,
                                activeTrackColor: const Color(0xFF8050AD),
                                onChanged: (_) => ref
                                    .read(themeModeProvider.notifier)
                                    .toggle(),
                              ),
                            ),
                            MoreMenuRow(
                              icon: Icons.translate_rounded,
                              title: t('language'),
                              subtitle: lang == AppLanguage.english
                                  ? 'English'
                                  : 'Filipino',
                              onTap: () => _openSubScreen(
                                title: t('language'),
                                body: const RiderLanguageView(),
                              ),
                            ),
                            MoreMenuRow(
                              icon: Icons.workspace_premium_outlined,
                              title: t('package_tier'),
                              subtitle: t('view_tier_benefits'),
                              onTap: () => _openSubScreen(
                                title: t('package_tier'),
                                body: const RiderPackageTierView(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
