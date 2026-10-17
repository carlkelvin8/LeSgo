import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../widgets/main/riderside/profile/rider_profile_header.dart';
import '../../../../widgets/main/riderside/profile/rider_profile_info_section.dart';
import '../../../../widgets/main/riderside/profile/rider_profile_summary_section.dart';
import '../../../../widgets/main/riderside/profile/rider_profile_settings_section.dart';
import '../../../../widgets/main/riderside/profile/profile_panel.dart';

class RiderProfileView extends ConsumerStatefulWidget {
  const RiderProfileView({super.key});
  @override
  ConsumerState<RiderProfileView> createState() => _RiderProfileViewState();
}

class _RiderProfileViewState extends ConsumerState<RiderProfileView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  final ScrollController _scroll = ScrollController();

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
    _scroll.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        (index * .10).clamp(0.0, .55),
        1.0,
        curve: Curves.easeOut,
      ),
    );
    final slide = _entrance.drive(
      CurveTween(
        curve: Interval(
          (index * .10).clamp(0.0, .55),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide.drive(
          Tween(begin: const Offset(0, .04), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final profile = ref.watch(riderProfileProvider);
    final isDark = profileDark(context);
    String t(String key) => AppLocalization.translate(key, lang);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > 668
        ? (width - 620) / 2
        : (width < 360 ? 16.0 : 24.0);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ColoredBox(
      color: isDark ? const Color(0xFF171320) : const Color(0xFFF8F7FB),
      child: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF6D3EA0),
            backgroundColor: isDark ? const Color(0xFF1E1730) : Colors.white,
            displacement: 100,
            onRefresh: () async {
              await Future.wait([
                ref.read(riderProfileProvider.notifier).loadProfile(),
                ref.read(riderWalletProvider.notifier).loadWallet(),
              ]);
            },
            child: CustomScrollView(
              controller: _scroll,
              key: const PageStorageKey('rider-profile-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Hero ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _reveal(0, const RiderProfileHeader()),
                    ),
                  ),
                ),

                // ── Loading bar ────────────────────────────────────────
                if (profile.isLoading)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFF8C5CB5),
                      backgroundColor: Colors.transparent,
                    ),
                  ),

                // ── Content ────────────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    22,
                    horizontal,
                    bottomPad + 28,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Error panel
                      if (profile.error != null) ...[
                        _reveal(
                          1,
                          ProfilePanel(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF8C5CB5),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t('rp_refresh_error'),
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 12.5,
                                      color: profileText(context),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: profile.isLoading
                                      ? null
                                      : () => ref
                                            .read(riderProfileProvider.notifier)
                                            .loadProfile(),
                                  child: Text(
                                    t('try_again'),
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 12,
                                      color: Color(0xFF6D3EA0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _reveal(2, const RiderProfileInfoSection()),
                      const SizedBox(height: 20),
                      _reveal(3, const RiderProfileSummarySection()),
                      const SizedBox(height: 20),
                      _reveal(4, const RiderProfileSettingsSection()),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
