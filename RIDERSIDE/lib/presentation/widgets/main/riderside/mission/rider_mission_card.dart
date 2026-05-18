import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';

class RiderMissionCard extends StatefulWidget {
  final RiderMission mission;
  final VoidCallback? onClaim;

  const RiderMissionCard({
    super.key,
    required this.mission,
    this.onClaim,
  });

  @override
  State<RiderMissionCard> createState() => _RiderMissionCardState();
}

class _RiderMissionCardState extends State<RiderMissionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 24)),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isExpanded ? 0.1 : 0.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isExpanded ? 0.2 : 0.0),
            ),
          ),
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
                            widget.mission.title,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                            ),
                          ),
                        ),
                        if (widget.mission.isCompleted && !widget.mission.rewardClaimed)
                          GestureDetector(
                            onTap: widget.onClaim,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE478),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
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
                        if (widget.mission.rewardClaimed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
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
                                    color: const Color(0xFFFBE478).withValues(alpha: 0.3),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  width: constraints.maxWidth * widget.mission.progress,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBE478),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              
                              // Progress Text
                              Positioned(
                                left: ResponsiveUtils.spacing(context, 12),
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    '${widget.mission.currentProgress} / ${widget.mission.goalTarget}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      color: Colors.white,
                                      fontSize: ResponsiveUtils.fontSize(context, 12),
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
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
                                    horizontal: ResponsiveUtils.spacing(context, 16),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent, // Transparent inner badge
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.mission.reward,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      color: Colors.white,
                                      fontSize: ResponsiveUtils.fontSize(context, 12),
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Expandable Description
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        height: _isExpanded ? null : 0,
                        margin: _isExpanded ? EdgeInsets.only(top: ResponsiveUtils.spacing(context, 12)) : EdgeInsets.zero,
                        child: Text(
                          widget.mission.description,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.white70,
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
