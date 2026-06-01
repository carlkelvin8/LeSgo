import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../domain/entities/missions/mission.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/missions/missions_provider.dart';

class MissionCard extends ConsumerWidget {
  final Mission mission;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/mission/Star.svg',
              width: ResponsiveUtils.fontSize(context, 48),
              height: ResponsiveUtils.fontSize(context, 48),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mission.title,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (mission.isCompleted && !mission.rewardClaimed)
                        GestureDetector(
                          onTap: mission.userId == 0
                              ? null
                              : () => _claimReward(context, ref),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.spacing(context, 8),
                              vertical: ResponsiveUtils.spacing(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Claim',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 10),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (mission.rewardClaimed)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 8),
                            vertical: ResponsiveUtils.spacing(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Claimed',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 10),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (mission.description != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      mission.description!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: mission.progressPercentage,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              mission.isCompleted ? Colors.green : Colors.white,
                            ),
                            minHeight: ResponsiveUtils.spacing(context, 8),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        '${mission.currentProgress}/${mission.goalTarget}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  if (mission.rewardValue > 0) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      'Reward: ₱${mission.rewardValue.toStringAsFixed(0)} ${mission.rewardType}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 10),
                        color: Colors.yellow.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _claimReward(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(missionsProvider.notifier).claimMission(mission.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reward claimed! ₱${mission.rewardValue.toStringAsFixed(0)} ${mission.rewardType}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
