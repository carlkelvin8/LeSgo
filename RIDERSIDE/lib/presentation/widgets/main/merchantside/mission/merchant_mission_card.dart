import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantMissionCard extends StatelessWidget {
  final String title;
  final String reward;
  final double progress;

  const MerchantMissionCard({
    super.key,
    required this.title,
    required this.reward,
    this.progress = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 40)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/images/mission/Star.svg',
            width: ResponsiveUtils.imageHeight(context, 48),
            height: ResponsiveUtils.imageHeight(context, 48),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                SizedBox(
                  height: ResponsiveUtils.spacing(context, 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
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
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: constraints.maxWidth * progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE478),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                reward,
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
