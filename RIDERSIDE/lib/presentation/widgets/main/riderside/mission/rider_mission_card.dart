import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';

class RiderMissionCard extends StatelessWidget {
  final RiderMission mission;
  final VoidCallback? onClaim;

  const RiderMissionCard({
    super.key,
    required this.mission,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 40)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star Icon
          SvgPicture.asset(
            'assets/images/mission/Star.svg',
            width: ResponsiveUtils.imageHeight(context, 48),
            height: ResponsiveUtils.imageHeight(context, 48),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),

          // Mission Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                        ),
                      ),
                    ),
                    if (mission.isCompleted && !mission.rewardClaimed)
                      GestureDetector(
                        onTap: onClaim,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFBE478),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CLAIM',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              color: Color(0xFF5F2D82),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (mission.rewardClaimed)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CLAIMED',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                // Progress Bar / Badge Container
                SizedBox(
                  height: ResponsiveUtils.spacing(context, 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Background (transparent yellow with border)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFBE478,
                                ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFBE478),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          // Filled Progress (solid yellow)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: constraints.maxWidth * mission.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE478),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // Purple Reward Badge (aligned to right)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.spacing(
                                  context,
                                  16,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors
                                    .transparent, // Transparent inner badge
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                mission.reward,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  color: Colors.white,
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    12,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
