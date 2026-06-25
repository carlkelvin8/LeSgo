import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';
import '../../../../widgets/widgets.dart';

class RiderMissionView extends ConsumerWidget {
  final bool includeBottomNavPadding;

  const RiderMissionView({
    super.key,
    this.includeBottomNavPadding = true,
  });

  void _handleBack(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    ref.read(riderNavProvider.notifier).navigateTo(RiderNavType.bookings);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(riderMissionProvider);
    final bottomPadding = includeBottomNavPadding
        ? ResponsiveUtils.scrollBottomPaddingForBottomNav(context)
        : ResponsiveUtils.spacing(context, 24);

    return Scaffold(
      backgroundColor: const Color(0xFF5F2D82),
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/mission/Background.svg',
              fit: BoxFit.cover,
            ),
          ),
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
                  borderColor: Colors.white.withValues(alpha: 0.5),
                  onBack: () => _handleBack(context, ref),
                ),
                Expanded(
                  child: missionState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : missionState.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Error loading missions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    missionState.error!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref
                                          .read(riderMissionProvider.notifier)
                                          .loadMissions();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref
                                    .read(riderMissionProvider.notifier)
                                    .loadMissions();
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  ResponsiveUtils.horizontalPadding(context),
                                  ResponsiveUtils.spacing(context, 32),
                                  ResponsiveUtils.horizontalPadding(context),
                                  bottomPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EARN REWARDS!',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize:
                                            ResponsiveUtils.fontSize(context, 26),
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      height: ResponsiveUtils.spacing(context, 4),
                                    ),
                                    Text(
                                      'Complete missions and get rewards.',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize:
                                            ResponsiveUtils.fontSize(context, 14),
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      height: ResponsiveUtils.spacing(context, 32),
                                    ),
                                    if (missionState.missions.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Text(
                                            'No missions available',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...missionState.missions.map(
                                        (mission) => RiderMissionCard(
                                          mission: mission,
                                          onClaim: () async {
                                            final success = await ref
                                                .read(riderMissionProvider.notifier)
                                                .claimReward(mission.id);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    success
                                                        ? '✅ Reward claimed! ${mission.reward} added to LesPay'
                                                        : '❌ Failed to claim reward',
                                                  ),
                                                  backgroundColor: success
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
