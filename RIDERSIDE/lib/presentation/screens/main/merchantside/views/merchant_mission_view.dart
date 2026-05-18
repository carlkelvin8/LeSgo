import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';
import '../../../../provider/main/merchantside/merchant_mission_provider.dart';

class MerchantMissionView extends ConsumerWidget {
  const MerchantMissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(merchantMissionProvider);

    return Stack(
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
                backgroundColor: Colors.transparent,
                logoColor: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.5),
              ),
              Expanded(
                child: missionState.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : missionState.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error loading missions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  missionState.error!,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(merchantMissionProvider.notifier).loadMissions();
                                  },
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(merchantMissionProvider.notifier).loadMissions();
                            },
                            child: SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.horizontalPadding(context),
                                vertical: ResponsiveUtils.spacing(context, 32),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EARN REWARDS!',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 26),
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                  Text(
                                    'Complete missions and get rewards.',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 14),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                                  if (missionState.missions.isEmpty)
                                    Center(
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
                                      (mission) => MerchantMissionCard(
                                        mission: mission,
                                        onClaim: () async {
                                          final success = await ref
                                              .read(merchantMissionProvider.notifier)
                                              .claimReward(mission.id);
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? '✅ Reward claimed! ${mission.reward} added to wallet'
                                                      : '❌ Failed to claim reward',
                                                ),
                                                backgroundColor: success ? Colors.green : Colors.red,
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
    );
  }
}
