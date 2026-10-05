import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../domain/entities/missions/mission.dart';
import '../../provider/missions/missions_provider.dart';

class MissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final int index;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.index = 0,
  });

  @override
  ConsumerState<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<MissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryAnim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) => _entryAnim.forward());
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    try {
      await ref.read(missionsProvider.notifier).claimMission(widget.mission.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Reward claimed! ₱${widget.mission.rewardValue.toStringAsFixed(0)} ${widget.mission.rewardType}',
          ),
          backgroundColor: const Color(0xFF22A060),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to claim: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final isComplete = m.isCompleted;
    final isClaimed = m.rewardClaimed;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              // Glassmorphism-style dark card
              color: AppColors.surface(context, Colors.black).withValues(alpha: .30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isComplete
                    ? const Color(0xFF44DD88).withValues(alpha: .50)
                    : Colors.white.withValues(alpha: .14),
                width: isComplete ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Star icon ───────────────────────────────────────
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .15),
                        width: .8,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        'assets/images/mission/Star.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ── Content ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + badge row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                m.title,
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            if (isClaimed)
                              _Badge(
                                label: 'Claimed',
                                bg: Colors.white.withValues(alpha: .18),
                                textColor: Colors.white70,
                              )
                            else if (isComplete)
                              GestureDetector(
                                onTap: m.userId == 0 ? null : _claimReward,
                                child: const _Badge(
                                  label: 'Claim',
                                  bg: Color(0xFF22A060),
                                  textColor: Colors.white,
                                  icon: Icons.card_giftcard_rounded,
                                ),
                              ),
                          ],
                        ),

                        // Description
                        if (m.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            m.description!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: .65),
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: m.progressPercentage.clamp(0.0, 1.0),
                                  backgroundColor:
                                      AppColors.surface(context, Colors.white).withValues(alpha: .18),
                                  valueColor: AlwaysStoppedAnimation(
                                    isComplete
                                        ? const Color(0xFF44DD88)
                                        : const Color(0xFFAA80FF),
                                  ),
                                  minHeight: 7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${m.currentProgress}/${m.goalTarget}',
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        // Reward label
                        if (m.rewardValue > 0) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_offer_rounded,
                                size: 11,
                                color: Color(0xFFFFDD55),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Reward: ₱${m.rewardValue.toStringAsFixed(0)} ${m.rewardType}',
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFDD55),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
