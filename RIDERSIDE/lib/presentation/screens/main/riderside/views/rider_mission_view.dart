import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../widgets/main/riderside/mission/rider_mission_card.dart';

class RiderMissionView extends ConsumerStatefulWidget {
  final bool includeBottomNavPadding;

  const RiderMissionView({
    super.key,
    this.includeBottomNavPadding = true,
  });

  @override
  ConsumerState<RiderMissionView> createState() => _RiderMissionViewState();
}

class _RiderMissionViewState extends ConsumerState<RiderMissionView>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final AnimationController _listAnim;
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _listAnim.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    ref.read(riderNavProvider.notifier).navigateTo(RiderNavType.bookings);
  }

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(riderMissionProvider);
    final bottomPadding = widget.includeBottomNavPadding
        ? ResponsiveUtils.scrollBottomPaddingForBottomNav(context)
        : ResponsiveUtils.spacing(context, 24);

    return Scaffold(
      backgroundColor: const Color(0xFF2A0850),
      body: Stack(
        children: [
          // ── Background SVG ──────────────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/mission/Background.svg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Animated dark overlay ───────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                          alpha: .30 + .08 * _bgAnim.value),
                      Colors.black.withValues(alpha: .55),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Aurora glow (animated) ──────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => CustomPaint(
                  painter: _AuroraPainter(t: _bgAnim.value),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  showBackButton: true,
                  backIconColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  logoColor: Colors.white,
                  borderColor: Colors.white.withValues(alpha: .30),
                  onBack: () => _handleBack(context),
                ),

                // ── Hero text ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _headerAnim,
                  builder: (_, __) {
                    final t = Curves.easeOutCubic.transform(_headerAnim.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - t)),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveUtils.horizontalPadding(context),
                            20,
                            ResponsiveUtils.horizontalPadding(context),
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .25),
                                    width: .8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events_rounded,
                                        size: 13, color: Color(0xFFFBE478)),
                                    SizedBox(width: 6),
                                    Text(
                                      'MISSIONS',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'EARN REWARDS!',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  letterSpacing: .5,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Complete missions and get rewards.',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: .72),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Mission list ──────────────────────────────────────────
                Expanded(
                  child: _buildBody(context, missionState, bottomPadding),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RiderMissionState missionState,
    double bottomPadding,
  ) {
    if (missionState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBE478)),
          strokeWidth: 2.5,
        ),
      );
    }

    if (missionState.error != null && missionState.missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: Colors.white70, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                missionState.error!,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    ref.read(riderMissionProvider.notifier).loadMissions(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE478),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A0850),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (missionState.missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.flag_rounded,
                  color: Colors.white70, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'No missions yet',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Check back soon!',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color: Colors.white.withValues(alpha: .60),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF5F2D82),
      backgroundColor: const Color(0xFFFBE478),
      onRefresh: () =>
          ref.read(riderMissionProvider.notifier).loadMissions(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.horizontalPadding(context),
          4,
          ResponsiveUtils.horizontalPadding(context),
          bottomPadding,
        ),
        itemCount: missionState.missions.length,
        itemBuilder: (context, index) {
          final mission = missionState.missions[index];
          // Stagger each card
          final start = (index * .08).clamp(0.0, .5);
          final end = (start + .5).clamp(0.0, 1.0);
          final itemAnim = CurvedAnimation(
            parent: _listAnim,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          );
          return AnimatedBuilder(
            animation: itemAnim,
            builder: (_, child) => Opacity(
              opacity: itemAnim.value,
              child: Transform.translate(
                offset: Offset(0, 28 * (1 - itemAnim.value)),
                child: child,
              ),
            ),
            child: RiderMissionCard(
              mission: mission,
              onClaim: () async {
                final success = await ref
                    .read(riderMissionProvider.notifier)
                    .claimReward(mission.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '✅ Reward claimed! ${mission.reward} added to LesPay'
                            : '❌ Failed to claim reward',
                      ),
                      backgroundColor: success
                          ? const Color(0xFF22A060)
                          : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Aurora painter ───────────────────────────────────────────────────────────
class _AuroraPainter extends CustomPainter {
  final double t;
  const _AuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final orbX = size.width * (.3 + .4 * t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = RadialGradient(
        colors: [
          const Color(0xFFAA44EE).withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(orbX, -size.height * .1),
        radius: size.width * .8,
      )),
    );
    // Shimmer sweep
    final beamX = -size.width * .3 + size.width * 1.6 * t;
    canvas.save();
    canvas.rotate(math.pi / 12);
    canvas.drawRect(
      Rect.fromLTWH(beamX, 0, size.width * .18, size.height * 1.5),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: .04),
          Colors.white.withValues(alpha: .07),
          Colors.white.withValues(alpha: .04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
          Rect.fromLTWH(beamX, 0, size.width * .18, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}
