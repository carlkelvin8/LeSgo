import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/loyalty/loyalty_provider.dart';
import 'loyalty_progress.dart';

const _brandPurple = Color(0xFF5F2D82);
const _brandMagenta = Color(0xFFB72AC8);
const _readyGreen = Color(0xFF2E7D32);

/// Icon + colours for a reward, chosen from the service it is for.
class RewardVisual {
  const RewardVisual(this.icon, this.colors);

  final IconData icon;
  final List<Color> colors;

  factory RewardVisual.of(LoyaltyReward reward) {
    final text = '${reward.title} ${reward.description}'.toLowerCase();
    if (text.contains('free delivery') || text.contains('delivery pass')) {
      return const RewardVisual(Icons.local_shipping_rounded, [
        Color(0xFF00897B),
        Color(0xFF4DB6AC),
      ]);
    }
    if (text.contains('ride')) {
      return const RewardVisual(Icons.two_wheeler_rounded, [
        Color(0xFF8E24AA),
        Color(0xFFCE93D8),
      ]);
    }
    if (text.contains('eat') || text.contains('food')) {
      return const RewardVisual(Icons.restaurant_rounded, [
        Color(0xFFEF6C00),
        Color(0xFFFFB74D),
      ]);
    }
    if (text.contains('lesgo') || text.contains('delivery')) {
      return const RewardVisual(Icons.inventory_2_rounded, [
        Color(0xFF1E88E5),
        Color(0xFF64B5F6),
      ]);
    }
    return const RewardVisual(Icons.card_giftcard_rounded, [
      _brandPurple,
      _brandMagenta,
    ]);
  }
}

TextStyle _ttFors(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
}) => TextStyle(
  fontFamily: 'TT Fors',
  fontSize: ResponsiveUtils.fontSize(context, size),
  fontWeight: weight,
  color: color,
  height: height,
);

/// Big balance card: the points, and how close the next reward is.
class PointsHeroCard extends StatelessWidget {
  const PointsHeroCard({
    super.key,
    required this.points,
    required this.nextGoal,
    required this.redeemableCount,
  });

  final int points;
  final LoyaltyReward? nextGoal;
  final int redeemableCount;

  @override
  Widget build(BuildContext context) {
    final goal = nextGoal;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandPurple, _brandMagenta],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandPurple.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft decorative circles, purely cosmetic.
          const Positioned(
            right: -30,
            top: -40,
            child: _Bubble(size: 150, alpha: 0.10),
          ),
          const Positioned(
            right: 40,
            bottom: -50,
            child: _Bubble(size: 110, alpha: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your points',
                      style: _ttFors(
                        context,
                        14,
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: points),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          LoyaltyProgress.format(value),
                          key: const ValueKey('points-balance'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ttFors(
                            context,
                            44,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'pts',
                        style: _ttFors(
                          context,
                          18,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal != null || redeemableCount > 0) ...[
                  const SizedBox(height: 16),
                  _GoalPanel(
                    points: points,
                    goal: goal,
                    redeemableCount: redeemableCount,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({
    required this.points,
    required this.goal,
    required this.redeemableCount,
  });

  final int points;
  final LoyaltyReward? goal;
  final int redeemableCount;

  @override
  Widget build(BuildContext context) {
    final g = goal;

    return Container(
      key: const ValueKey('goal-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (redeemableCount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: g != null ? 12 : 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      redeemableCount == 1
                          ? '1 reward is ready to redeem!'
                          : '$redeemableCount rewards are ready to redeem!',
                      key: const ValueKey('ready-banner'),
                      style: _ttFors(
                        context,
                        13.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (g != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Next reward: ${g.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ttFors(
                      context,
                      13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${LoyaltyProgress.format(LoyaltyProgress.pointsToGo(points, g.pointsCost))} pts to go',
                  key: const ValueKey('next-goal-togo'),
                  style: _ttFors(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const ValueKey('next-goal-progress'),
                value: LoyaltyProgress.fraction(points, g.pointsCost),
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Earn more points" shortcuts: the two things in the app that give points.
class EarnPointsRow extends StatelessWidget {
  const EarnPointsRow({
    super.key,
    required this.onInvite,
    required this.onMissions,
  });

  final VoidCallback onInvite;
  final VoidCallback onMissions;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight: the tiles stretch to the same height, which a Row cannot
    // do on its own inside a ListView (unbounded height).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _EarnTile(
              key: const ValueKey('earn-invite'),
              icon: Icons.person_add_alt_1_rounded,
              title: 'Invite friends',
              subtitle: 'Earn points when they join',
              onTap: onInvite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EarnTile(
              key: const ValueKey('earn-missions'),
              icon: Icons.emoji_events_rounded,
              title: 'Missions',
              subtitle: 'Complete tasks, get rewarded',
              onTap: onMissions,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  const _EarnTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brandPurple);

    return Material(
      color: AppColors.surface(context, Colors.white),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border(context, const Color(0xFFE7DCEF)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: _ttFors(
                  context,
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: _ttFors(
                  context,
                  12,
                  color: AppColors.foreground(context, Colors.grey[600]!),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One reward: what it is, how close the customer is, and a clear way to claim.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.points,
    required this.isRedeeming,
    required this.onRedeem,
  });

  final LoyaltyReward reward;
  final int points;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final visual = RewardVisual.of(reward);
    final ready = LoyaltyProgress.canRedeem(reward, points);
    final toGo = LoyaltyProgress.pointsToGo(points, reward.pointsCost);
    final accent = AppColors.accent(context, _brandPurple);

    return Container(
      key: ValueKey('reward-card-${reward.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ready
              ? visual.colors.first.withValues(alpha: 0.75)
              : AppColors.border(context, const Color(0xFFE7DCEF)),
          width: ready ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (ready ? visual.colors.first : Colors.black).withValues(
              alpha: ready ? 0.16 : 0.05,
            ),
            blurRadius: ready ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: visual.colors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(visual.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: _ttFors(
                          context,
                          16,
                          weight: FontWeight.w800,
                          color: AppColors.foreground(context, Colors.black87),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: _ttFors(
                          context,
                          12.5,
                          color: AppColors.foreground(
                            context,
                            Colors.grey[600]!,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CostPill(cost: reward.pointsCost, highlighted: ready),
              ],
            ),
            const SizedBox(height: 14),
            if (!reward.available)
              _StatusLine(
                key: ValueKey('reward-status-${reward.id}'),
                icon: Icons.block_rounded,
                color: Colors.grey,
                text: 'Currently unavailable',
              )
            else if (ready) ...[
              _StatusLine(
                key: ValueKey('reward-status-${reward.id}'),
                icon: Icons.check_circle_rounded,
                color: _readyGreen,
                text: 'You have enough points!',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: ValueKey('redeem-button-${reward.id}'),
                  onPressed: isRedeeming ? null : onRedeem,
                  icon: const Icon(Icons.redeem_rounded, size: 20),
                  label: Text(
                    'Redeem now',
                    style: _ttFors(context, 15, weight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: ValueKey('reward-progress-${reward.id}'),
                  value: LoyaltyProgress.fraction(points, reward.pointsCost),
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    visual.colors.first,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 15, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${LoyaltyProgress.format(points)} / ${LoyaltyProgress.format(reward.pointsCost)} pts',
                      style: _ttFors(
                        context,
                        12.5,
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                  ),
                  Text(
                    '${LoyaltyProgress.format(toGo)} more to unlock',
                    key: ValueKey('reward-togo-${reward.id}'),
                    style: _ttFors(
                      context,
                      12.5,
                      weight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({required this.cost, required this.highlighted});

  final int cost;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brandPurple);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? accent : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            size: 14,
            color: highlighted ? AppColors.onAccent(context) : accent,
          ),
          const SizedBox(width: 4),
          Text(
            LoyaltyProgress.format(cost),
            style: _ttFors(
              context,
              12.5,
              weight: FontWeight.w800,
              color: highlighted ? AppColors.onAccent(context) : accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: _ttFors(context, 13, weight: FontWeight.w700, color: color),
        ),
      ),
    ],
  );
}

/// Shown when the catalogue has no rewards.
class RewardsEmptyState extends StatelessWidget {
  const RewardsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brandPurple);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard_rounded, size: 40, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            'No rewards available yet.',
            style: _ttFors(
              context,
              15,
              weight: FontWeight.w700,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep collecting points. New rewards are coming soon.',
            textAlign: TextAlign.center,
            style: _ttFors(
              context,
              12.5,
              color: AppColors.foreground(context, Colors.grey[600]!),
            ),
          ),
        ],
      ),
    );
  }
}
