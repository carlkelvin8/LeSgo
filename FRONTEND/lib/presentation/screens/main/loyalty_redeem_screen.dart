import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/loyalty/loyalty_provider.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../../widgets/common/retry_widget.dart';
import '../../widgets/loyalty/loyalty_progress.dart';
import '../../widgets/loyalty/loyalty_widgets.dart';
import '../../widgets/profile/invite_friends_sheet.dart';

class LoyaltyRedeemScreen extends ConsumerStatefulWidget {
  const LoyaltyRedeemScreen({super.key});

  @override
  ConsumerState<LoyaltyRedeemScreen> createState() =>
      _LoyaltyRedeemScreenState();
}

class _LoyaltyRedeemScreenState extends ConsumerState<LoyaltyRedeemScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).refreshProfile();
      ref.read(loyaltyProvider.notifier).loadRewards();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(profileProvider.notifier).refreshProfile(),
      ref.read(loyaltyProvider.notifier).loadRewards(),
    ]);
  }

  Future<void> _redeem(LoyaltyReward reward, int points) async {
    final left = points - reward.pointsCost;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem reward?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reward.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Spend ${LoyaltyProgress.format(reward.pointsCost)} points for this reward. '
              'You will have ${LoyaltyProgress.format(left)} points left.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(loyaltyProvider.notifier)
        .redeemReward(reward, points);
    if (!mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, 'Reward redeemed successfully!');
      await ref.read(profileProvider.notifier).refreshProfile();
    }
  }

  Widget _sectionTitle(String text, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w800,
                color: AppColors.accent(context, const Color(0xFF5F2D82)),
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12.5),
                color: AppColors.foreground(context, Colors.grey[600]!),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final profileState = ref.watch(profileProvider);
    final points = profileState.points;
    final rewards = LoyaltyProgress.sorted(points, loyaltyState.rewards);

    return Scaffold(
      backgroundColor: AppColors.surface(context, const Color(0xFFF8F4FB)),
      appBar: AppBar(
        title: const Text('Redeem Points'),
        elevation: 0,
      ),
      body: loyaltyState.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
            )
          : loyaltyState.error != null && loyaltyState.rewards.isEmpty
          ? RetryWidget(
              message: loyaltyState.error!,
              isLoading: loyaltyState.isRedeeming,
              onRetry: _refreshAll,
            )
          : RefreshIndicator(
              color: AppColors.accent(context, const Color(0xFF5F2D82)),
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                children: [
                  PointsHeroCard(
                    points: points,
                    nextGoal: LoyaltyProgress.nextGoal(
                      points,
                      loyaltyState.rewards,
                    ),
                    redeemableCount: LoyaltyProgress.redeemableCount(
                      points,
                      loyaltyState.rewards,
                    ),
                  ),
                  if (loyaltyState.error != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Text(
                      loyaltyState.error!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                  SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                  _sectionTitle('Earn more points'),
                  EarnPointsRow(
                    onInvite: () => InviteFriendsSheet.show(
                      context,
                      referralCode: profileState.referralCode,
                      userName: profileState.name,
                    ),
                    onMissions: () =>
                        AppRouter.push(context, MainRoutes.missions),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 28)),
                  _sectionTitle(
                    'Rewards',
                    trailing: rewards.isEmpty
                        ? null
                        : '${rewards.length} available',
                  ),
                  if (rewards.isEmpty)
                    const RewardsEmptyState()
                  else
                    ...rewards.map(
                      (reward) => RewardCard(
                        reward: reward,
                        points: points,
                        isRedeeming: loyaltyState.isRedeeming,
                        onRedeem: () => _redeem(reward, points),
                      ),
                    ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                ],
              ),
            ),
    );
  }
}
