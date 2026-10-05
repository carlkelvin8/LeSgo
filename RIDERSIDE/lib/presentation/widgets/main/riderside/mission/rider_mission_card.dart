import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _RiderMissionCardState extends State<RiderMissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
    );
    _rotateAnim = Tween<double>(begin: 0, end: .5).animate(
      CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final isComplete = m.isCompleted;
    final isClaimed = m.rewardClaimed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _expandCtrl,
        builder: (_, __) => GestureDetector(
          onTap: _toggle,
          child: Container(
            decoration: BoxDecoration(
              // Glassmorphism dark card
              color: isComplete
                  ? const Color(0xFFFBE478).withValues(alpha: .08)
                  : Colors.black.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isComplete
                    ? const Color(0xFFFBE478).withValues(alpha: .45)
                    : Colors.white.withValues(alpha: .12),
                width: isComplete ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .20),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Star icon in container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .12),
                          width: .8,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        'assets/images/mission/Star.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isClaimed)
                                _Badge(
                                  label: 'CLAIMED',
                                  bg: Colors.white.withValues(alpha: .15),
                                  textColor: Colors.white60,
                                )
                              else if (isComplete)
                                GestureDetector(
                                  onTap: widget.onClaim,
                                  child: const _Badge(
                                    label: 'CLAIM',
                                    bg: Color(0xFFFBE478),
                                    textColor: Color(0xFF2A0850),
                                    icon: Icons.card_giftcard_rounded,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Progress bar
                          _ProgressBar(
                            progress: m.progress.clamp(0.0, 1.0),
                            current: m.currentProgress,
                            goal: m.goalTarget,
                            reward: m.reward,
                            isComplete: isComplete,
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 6),
                      child: RotationTransition(
                        turns: _rotateAnim,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: .60),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Expandable description ──────────────────────────────
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: FadeTransition(
                    opacity: _expandAnim,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, left: 58),
                      child: Text(
                        m.description,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .65),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  final int current;
  final int goal;
  final String reward;
  final bool isComplete;

  const _ProgressBar({
    required this.progress,
    required this.current,
    required this.goal,
    required this.reward,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels row
        Row(
          children: [
            Text(
              '$current / $goal',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer_rounded,
                    size: 11, color: Color(0xFFFBE478)),
                const SizedBox(width: 4),
                Text(
                  reward,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFBE478),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: .15),
            valueColor: AlwaysStoppedAnimation(
              isComplete ? const Color(0xFF44DD88) : const Color(0xFFFBE478),
            ),
          ),
        ),
      ],
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}
