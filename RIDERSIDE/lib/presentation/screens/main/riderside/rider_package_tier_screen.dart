import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/rider_package_api.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../presentation/provider/main/riderside/rider_package_provider.dart';
import '../../../../presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'rider_package_payment_screen.dart';

// ─── Tier theme ───────────────────────────────────────────────────────────────
class _TierTheme {
  final List<Color> gradient;
  final Color accent;
  final IconData icon;

  const _TierTheme(
      {required this.gradient, required this.accent, required this.icon});
}

const _themes = {
  'basic': _TierTheme(
    gradient: [Color(0xFF374151), Color(0xFF1F2937), Color(0xFF111827)],
    accent: Color(0xFF9CA3AF),
    icon: Icons.person_outline_rounded,
  ),
  'advance': _TierTheme(
    gradient: [Color(0xFF5B21B6), Color(0xFF4C1D95), Color(0xFF1E0058)],
    accent: Color(0xFFA78BFA),
    icon: Icons.rocket_launch_rounded,
  ),
  'pro': _TierTheme(
    gradient: [Color(0xFF1D4ED8), Color(0xFF1E3A8A), Color(0xFF0C1A4A)],
    accent: Color(0xFF60A5FA),
    icon: Icons.workspace_premium_rounded,
  ),
  'elite': _TierTheme(
    gradient: [Color(0xFFB45309), Color(0xFF92400E), Color(0xFF451A03)],
    accent: Color(0xFFFBBF24),
    icon: Icons.military_tech_rounded,
  ),
  'employee': _TierTheme(
    gradient: [Color(0xFF0E7490), Color(0xFF164E63), Color(0xFF042F2E)],
    accent: Color(0xFF22D3EE),
    icon: Icons.badge_rounded,
  ),
};

_TierTheme _themeFor(String tier) =>
    _themes[tier.toLowerCase()] ?? _themes['basic']!;

// ─── Screen ───────────────────────────────────────────────────────────────────
class RiderPackageTierView extends ConsumerStatefulWidget {
  const RiderPackageTierView({super.key});

  @override
  ConsumerState<RiderPackageTierView> createState() =>
      _RiderPackageTierViewState();
}

class _RiderPackageTierViewState extends ConsumerState<RiderPackageTierView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1000),
  )..forward();
  late final AnimationController _heroBg = AnimationController(
    vsync: this, duration: const Duration(seconds: 6),
  )..repeat(reverse: true);
  late final AnimationController _heroShimmer = AnimationController(
    vsync: this, duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  int _selectedIndex = 0;
  late final PageController _pageCtrl = PageController(
    viewportFraction: .80,
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(riderPackageProvider.notifier).loadCatalog(),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _heroBg.dispose();
    _heroShimmer.dispose();
    _pulse.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((i * .08).clamp(0.0, .55), 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: fade.drive(
          Tween(begin: const Offset(0, .06), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  Future<void> _handleUpgrade(RiderPackageOption option) async {
    final lang = ref.read(appLanguageProvider);
    final wallet = ref.read(riderWalletProvider);
    final price = option.oneTimePrice ?? 0;
    final canUseLesPay = wallet.balance >= price;

    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(
        option: option,
        lang: lang,
        canUseLesPay: canUseLesPay,
      ),
    );

    if (!mounted || method == null) return;

    final notifier = ref.read(riderPackageProvider.notifier);
    final checkout = method == 'lespay'
        ? await notifier.upgradeWithLesPay(option.tier)
        : await notifier.startXenditUpgrade(option.tier);

    if (!mounted) return;
    if (checkout == null) {
      final error = ref.read(riderPackageProvider).error;
      if (error != null) SnackBarUtils.showError(context, error);
      return;
    }

    if (checkout.isCompleted) {
      SnackBarUtils.showSuccess(context, 'Upgraded to ${checkout.targetLabel}');
      return;
    }

    if (checkout.needsPayment && checkout.invoiceUrl != null) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (_) => RiderPackagePaymentScreen(checkout: checkout)),
      );
      if (!mounted) return;
      if (ok == true) {
        SnackBarUtils.showSuccess(context, 'Upgraded to ${checkout.targetLabel}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final pkg = ref.watch(riderPackageProvider);
    final catalog = pkg.catalog;

    if (pkg.isLoading && catalog == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0118),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B55CC)),
        ),
      );
    }

    if (catalog == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0118),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFF8B55CC), size: 40),
              const SizedBox(height: 16),
              Text(
                pkg.error ?? 'Could not load packages',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(riderPackageProvider.notifier).loadCatalog(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final packages = catalog.packages;
    final currentIdx =
        packages.indexWhere((p) => p.isCurrent).clamp(0, packages.length - 1);
    final selected = packages[_selectedIndex.clamp(0, packages.length - 1)];
    final theme = _themeFor(selected.tier);
    final features = _featuresFor(selected);
    final safePad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0118),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .18),
                  width: .8,
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Text(
          'Package Tier',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(riderPackageProvider.notifier).loadCatalog(),
        color: const Color(0xFF8B55CC),
        backgroundColor: const Color(0xFF1A0A2E),
        child: Stack(
          children: [
            // ── Animated full-screen background ──────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_heroBg, _heroShimmer]),
                builder: (_, __) => CustomPaint(
                  painter: _FullBgPainter(
                    colors: theme.gradient,
                    t: _heroBg.value,
                    sweep: _heroShimmer.value,
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Safe-area top gap
                SliverToBoxAdapter(
                    child: SizedBox(height: safePad.top + kToolbarHeight + 8)),

                // ── Current tier badge ──────────────────────────────
                SliverToBoxAdapter(
                  child: _reveal(
                    0,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _CurrentBadge(
                        label: catalog.currentLabel,
                        theme: _themeFor(packages[currentIdx].tier),
                        pulse: _pulse,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Tier selector cards (horizontal pager) ──────────
                SliverToBoxAdapter(
                  child: _reveal(
                    1,
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: packages.length,
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIndex = i);
                        },
                        itemBuilder: (context, i) {
                          final p = packages[i];
                          final t = _themeFor(p.tier);
                          final isSelected = i == _selectedIndex;
                          return AnimatedScale(
                            scale: isSelected ? 1.0 : .88,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: GestureDetector(
                              onTap: () {
                                _pageCtrl.animateToPage(
                                  i,
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: _TierCard(
                                option: p,
                                theme: t,
                                isSelected: isSelected,
                                isCurrent: p.isCurrent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Page indicator dots
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(packages.length, (i) {
                        final sel = i == _selectedIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: sel ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: sel
                                ? theme.accent
                                : Colors.white.withValues(alpha: .25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Features for selected tier ──────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _reveal(
                      2,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTag(label: 'WHAT\'S INCLUDED'),
                          const SizedBox(height: 14),
                          ...features.asMap().entries.map((e) => _FeatureRow(
                                icon: e.value.icon,
                                label: e.value.label,
                                accent: theme.accent,
                                index: e.key,
                                entrance: _entrance,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── All plans comparison (collapsed list) ───────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _reveal(
                      3,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTag(label: 'ALL PLANS'),
                          const SizedBox(height: 14),
                          ...packages.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PlanRow(
                                  option: e.value,
                                  theme: _themeFor(e.value.tier),
                                  isSelected: e.key == _selectedIndex,
                                  isProcessing: pkg.isProcessing,
                                  onSelect: () {
                                    _pageCtrl.animateToPage(
                                      e.key,
                                      duration: const Duration(
                                          milliseconds: 350),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                      height: safePad.bottom + 100),
                ),
              ],
            ),

            // ── Sticky bottom CTA ─────────────────────────────────────
            if (selected.isUpgradeable)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyUpgradeCTA(
                  option: selected,
                  theme: theme,
                  isProcessing: pkg.isProcessing,
                  lang: lang,
                  safePad: safePad,
                  onTap: () => _handleUpgrade(selected),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_Feature> _featuresFor(RiderPackageOption option) => [
        _Feature(Icons.trending_up_rounded, option.profitShareLabel),
        _Feature(Icons.directions_car_rounded, 'Booking access'),
        _Feature(Icons.support_agent_rounded, 'Admin support'),
        if (option.tier == 'pro')
          _Feature(Icons.local_offer_rounded, 'Exclusive promotions'),
        if (option.tier == 'employee')
          _Feature(Icons.payments_rounded, 'Company-managed salary'),
      ];
}

// ─── Full background painter ──────────────────────────────────────────────────
class _FullBgPainter extends CustomPainter {
  final List<Color> colors;
  final double t;
  final double sweep;
  const _FullBgPainter(
      {required this.colors, required this.t, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect),
    );
    // Drifting aurora
    final orbX = size.width * (.4 + .35 * t);
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(
        colors: [colors[0].withValues(alpha: .35), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(orbX, -size.height * .05), radius: size.width * .80)),
    );
    // Bottom glow
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(
        colors: [colors[1].withValues(alpha: .30), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * .5, size.height * 1.05),
          radius: size.width * .70)),
    );
    // Particles
    final rng = math.Random(77);
    final pp = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 24; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * math.pi * 2;
      final spd = .3 + rng.nextDouble() * .6;
      final r = .5 + rng.nextDouble() * 1.8;
      final px = bx + math.sin(t * math.pi * 2 * spd + phase) * 10;
      final py = by + math.cos(t * math.pi * 2 * spd + phase) * 8;
      final a = (.03 + rng.nextDouble() * .07) *
          (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase));
      pp.color = colors[0].withValues(alpha: a * 2.5);
      canvas.drawCircle(Offset(px, py), r, pp);
    }
    // Shimmer sweep
    final bx2 = -size.width * .3 + size.width * 1.6 * sweep;
    canvas.save();
    canvas.transform(Matrix4(
      math.cos(math.pi / 10), math.sin(math.pi / 10), 0, 0,
      -math.sin(math.pi / 10), math.cos(math.pi / 10), 0, 0,
      0, 0, 1, 0, 0, -size.height * .15, 0, 1,
    ).storage);
    canvas.drawRect(
      Rect.fromLTWH(bx2, -20, size.width * .18, size.height * 1.6),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent, Colors.white.withValues(alpha: .04),
          Colors.white.withValues(alpha: .07), Colors.white.withValues(alpha: .04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
          Rect.fromLTWH(bx2, 0, size.width * .18, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FullBgPainter old) =>
      old.t != t || old.sweep != sweep || old.colors != colors;
}

// ─── Current badge ────────────────────────────────────────────────────────────
class _CurrentBadge extends StatelessWidget {
  final String label;
  final _TierTheme theme;
  final AnimationController pulse;

  const _CurrentBadge(
      {required this.label, required this.theme, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: .15 + .08 * pulse.value),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.accent.withValues(alpha: .30 + .15 * pulse.value),
                width: .8,
              ),
            ),
            child: Icon(theme.icon, color: theme.accent, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PLAN',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: .45),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.accent,
                  letterSpacing: -.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: .12),
                width: .8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF34D399).withValues(
                        alpha: .8 + .2 * pulse.value),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399)
                            .withValues(alpha: .4 * pulse.value),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34D399),
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

// ─── Tier card ────────────────────────────────────────────────────────────────
class _TierCard extends StatelessWidget {
  final RiderPackageOption option;
  final _TierTheme theme;
  final bool isSelected;
  final bool isCurrent;

  const _TierCard({
    required this.option,
    required this.theme,
    required this.isSelected,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? theme.accent.withValues(alpha: .60)
              : Colors.white.withValues(alpha: .08),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.accent.withValues(alpha: .25),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: CustomPaint(
        painter: _CardMiniPainter(
          colors: theme.gradient,
          selected: isSelected,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.accent.withValues(alpha: .30),
                        width: .8,
                      ),
                    ),
                    child: Icon(theme.icon, color: theme.accent, size: 20),
                  ),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF34D399).withValues(alpha: .30),
                          width: .8,
                        ),
                      ),
                      child: const Text(
                        'Yours',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                option.label,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                option.profitShareLabel,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: .60),
                ),
              ),
              const SizedBox(height: 12),
              if (option.oneTimePrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₱${option.oneTimePrice!.toStringAsFixed(0)} one-time',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMiniPainter extends CustomPainter {
  final List<Color> colors;
  final bool selected;
  const _CardMiniPainter({required this.colors, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors[0].withValues(alpha: selected ? .90 : .55),
          colors[1].withValues(alpha: selected ? .85 : .50),
          colors[2].withValues(alpha: selected ? .95 : .65),
        ],
      ).createShader(Offset.zero & size),
    );
    // Top-right glow
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: selected ? .12 : .05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width, 0), radius: size.width * .60)),
    );
  }

  @override
  bool shouldRepaint(covariant _CardMiniPainter old) =>
      old.selected != selected || old.colors != colors;
}

// ─── Feature row ──────────────────────────────────────────────────────────────
class _FeatureRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final int index;
  final AnimationController entrance;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.index,
    required this.entrance,
  });

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _check = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 400 + widget.index * 100), () {
      if (mounted) _check.forward();
    });
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 17, color: widget.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _check,
              builder: (_, __) => Transform.scale(
                scale: CurvedAnimation(
                        parent: _check, curve: Curves.elasticOut)
                    .value,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22A060),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22A060).withValues(alpha: .35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan row (all plans list) ────────────────────────────────────────────────
class _PlanRow extends StatefulWidget {
  final RiderPackageOption option;
  final _TierTheme theme;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback onSelect;

  const _PlanRow({
    required this.option,
    required this.theme,
    required this.isSelected,
    required this.isProcessing,
    required this.onSelect,
  });

  @override
  State<_PlanRow> createState() => _PlanRowState();
}

class _PlanRowState extends State<_PlanRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(
        scale: 1.0 - .015 * _press.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.theme.accent.withValues(alpha: .12)
                : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? widget.theme.accent.withValues(alpha: .45)
                  : Colors.white.withValues(alpha: .08),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.theme.gradient[0], widget.theme.gradient[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.theme.icon,
                    size: 18, color: widget.theme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.option.profitShareLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: .50),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.option.oneTimePrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: .20),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: .40),
                      width: .8,
                    ),
                  ),
                  child: Text(
                    '₱${widget.option.oneTimePrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
              if (widget.option.isCurrent) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFF34D399)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section tag ──────────────────────────────────────────────────────────────
class _SectionTag extends StatelessWidget {
  final String label;
  const _SectionTag({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: Colors.white.withValues(alpha: .40),
    ),
  );
}

// ─── Sticky upgrade CTA ───────────────────────────────────────────────────────
class _StickyUpgradeCTA extends StatefulWidget {
  final RiderPackageOption option;
  final _TierTheme theme;
  final bool isProcessing;
  final AppLanguage lang;
  final EdgeInsets safePad;
  final VoidCallback onTap;

  const _StickyUpgradeCTA({
    required this.option,
    required this.theme,
    required this.isProcessing,
    required this.lang,
    required this.safePad,
    required this.onTap,
  });

  @override
  State<_StickyUpgradeCTA> createState() => _StickyUpgradeCTAState();
}

class _StickyUpgradeCTAState extends State<_StickyUpgradeCTA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, widget.safePad.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0118).withValues(alpha: .92),
        border: Border(
          top: BorderSide(
            color: widget.theme.accent.withValues(alpha: .20),
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.isProcessing ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, child) => Transform.scale(
            scale: 1.0 - .02 * _press.value,
            child: child,
          ),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isProcessing
                    ? [
                        widget.theme.gradient[0].withValues(alpha: .5),
                        widget.theme.gradient[1].withValues(alpha: .5),
                      ]
                    : [widget.theme.gradient[0], widget.theme.gradient[1]],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: widget.theme.accent.withValues(alpha: .35),
                width: .8,
              ),
              boxShadow: widget.isProcessing
                  ? []
                  : [
                      BoxShadow(
                        color: widget.theme.gradient[0].withValues(alpha: .40),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: Center(
              child: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.theme.icon,
                            color: widget.theme.accent, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalization.translate(
                                  'upgrade_to', widget.lang)
                              .replaceAll(
                                  '{{tier}}', widget.option.label),
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.option.oneTimePrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₱${widget.option.oneTimePrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: widget.theme.accent,
                              ),
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

// ─── Payment sheet ────────────────────────────────────────────────────────────
class _PaymentSheet extends StatelessWidget {
  final RiderPackageOption option;
  final AppLanguage lang;
  final bool canUseLesPay;

  const _PaymentSheet({
    required this.option,
    required this.lang,
    required this.canUseLesPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(option.tier);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: theme.accent.withValues(alpha: .18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Icon(theme.icon, color: theme.accent, size: 32),
          const SizedBox(height: 12),
          Text(
            'Upgrade to ${option.label}',
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${option.priceLabel} · ${option.profitShareLabel}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: Colors.white.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 26),
          if (canUseLesPay)
            _PayBtn(
              label: 'Pay with LesPay',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF5A1E88),
              onTap: () => Navigator.pop(context, 'lespay'),
            ),
          if (canUseLesPay) const SizedBox(height: 10),
          _PayBtn(
            label: 'Pay online',
            icon: Icons.credit_card_rounded,
            color: theme.gradient[0],
            onTap: () => Navigator.pop(context, 'xendit'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalization.translate('cancel', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PayBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.lerp(color, Colors.black, .25)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: .10),
            width: .8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}
