import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../provider/missions/missions_provider.dart';
import '../../widgets/missions/mission_card.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionsProvider);
    final missions = state.missions;
    final completed = missions.where((mission) => mission.isCompleted).length;
    final notifier = ref.read(missionsProvider.notifier);
    final background = AppColors.surface(context, const Color(0xFFF8F5FB));
    final accent = AppColors.buttonFill(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Missions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              color: accent,
              onRefresh: notifier.refreshMissions,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: missions.isEmpty ? 2 : missions.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return const _MissionsHero();
                  if (missions.isEmpty) {
                    return _MissionsPlaceholder(
                      state: state,
                      onRetry: notifier.refreshMissions,
                    );
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 20, 2, 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Your challenges',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '$completed of ${missions.length} complete',
                              textAlign: TextAlign.end,
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(color: accent),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final mission = missions[index - 2];
                  return Padding(
                    key: ValueKey(mission.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MissionCard(
                      mission: mission,
                      onTap:
                          !mission.isCompleted &&
                              mission.missionType == 'app_review'
                          ? () => notifier.performMissionAction(mission)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionsHero extends StatelessWidget {
  const _MissionsHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF221035), Color(0xFF573285)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -44,
              top: -60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x226FDACD), width: 28),
                ),
                child: const SizedBox.square(dimension: 220),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 10, 17),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(26) > 32;
                  final artwork = ExcludeSemantics(
                    child: SvgPicture.asset(
                      'assets/images/mission/Banner.svg',
                      height: compact ? 104 : 135,
                    ),
                  );
                  const copy = _HeroCopy();
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            copy,
                            Align(
                              alignment: Alignment.centerRight,
                              child: artwork,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Expanded(flex: 6, child: copy),
                            Expanded(flex: 5, child: artwork),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.confirmation_number_outlined,
          color: Color(0xFFBFF0D9),
          size: 24,
        ),
        SizedBox(height: 9),
        Text(
          'Earn vouchers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Complete missions to unlock rewards for your orders.',
          style: TextStyle(color: Color(0xFFEBDEF6), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

class _MissionsPlaceholder extends StatelessWidget {
  const _MissionsPlaceholder({required this.state, required this.onRetry});

  final MissionsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    final accent = AppColors.buttonFill(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          border: Border.all(
            color: AppColors.border(context, const Color(0xFFE8DFED)),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: state.isLoading
            ? Center(child: CircularProgressIndicator(color: accent))
            : Column(
                children: [
                  Icon(
                    error == null
                        ? Icons.emoji_events_outlined
                        : Icons.wifi_off_rounded,
                    color: accent,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error ?? 'No missions right now',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (error == null)
                    const Text(
                      'Check back for new challenges.',
                      textAlign: TextAlign.center,
                    )
                  else
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                ],
              ),
      ),
    );
  }
}
