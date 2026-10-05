import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/missions/missions_provider.dart';
import '../../widgets/widgets.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsState = ref.watch(missionsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Background SVG ─────────────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/mission/Background.svg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Darkening overlay for better readability ───────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .25),
                    Colors.black.withValues(alpha: .55),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.spacing(context, 16),
                      ),
                      child: const AuthHeader(
                        title: 'Mission',
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: ResponsiveUtils.spacing(context, 35),
                      left: ResponsiveUtils.spacing(context, 6),
                      right: ResponsiveUtils.spacing(context, 6),
                      // This decoration overlaps the header. Let taps reach
                      // its Back button rather than the loaded SVG picture.
                      child: IgnorePointer(
                        child: SvgPicture.asset(
                          'assets/images/mission/Banner.svg',
                          height: ResponsiveUtils.imageHeight(context, 300),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 248)),

                // ── Section label ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EARN VOUCHERS!',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          letterSpacing: .5,
                          shadows: [
                            Shadow(
                              color: Color(0x88000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Complete missions and get vouchers for your orders.',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Mission list ──────────────────────────────────────────
                Expanded(
                  child: _buildBody(context, ref, missionsState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, dynamic missionsState) {
    if (missionsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (missionsState.error != null && missionsState.missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                missionsState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(missionsProvider.notifier).refreshMissions(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (missionsState.missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Colors.white70,
                size: 30,
              ),
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
            const SizedBox(height: 6),
            Text(
              'Check back soon for new challenges!',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color: Colors.white.withValues(alpha: .65),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF5F2D82),
      onRefresh: () =>
          ref.read(missionsProvider.notifier).refreshMissions(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: missionsState.missions.length,
        itemBuilder: (context, index) {
          final mission = missionsState.missions[index];
          return MissionCard(
            mission: mission,
            index: index,
            onTap: () {
              if (mission.isCompleted) return;
              if (mission.missionType == 'app_review') {
                ref
                    .read(missionsProvider.notifier)
                    .performMissionAction(mission);
              }
            },
          );
        },
      ),
    );
  }
}
