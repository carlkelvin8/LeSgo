import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/loyalty/loyalty_provider.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../../widgets/common/retry_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final profileState = ref.watch(profileProvider);
    final points = profileState.points;

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      appBar: AppBar(
        title: Text(
          'Redeem Points',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: loyaltyState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : loyaltyState.error != null && loyaltyState.rewards.isEmpty
              ? RetryWidget(
                  message: loyaltyState.error!,
                  isLoading: loyaltyState.isRedeeming,
                  onRetry: () => _refreshAll(),
                )
              : RefreshIndicator(
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                  onRefresh: _refreshAll,
                  child: ListView(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 20),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          ResponsiveUtils.spacing(context, 20),
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5F2D82), Color(0xFFB72AC8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your points',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 8),
                            ),
                            Text(
                              '$points pts',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                color: Colors.white,
                                fontSize: ResponsiveUtils.fontSize(context, 32),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                      Text(
                        'Available rewards',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 18),
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent(context, Color(0xFF5F2D82)),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      if (loyaltyState.rewards.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.spacing(context, 32),
                          ),
                          child: Center(
                            child: Text(
                              'No rewards available yet.',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                            ),
                          ),
                        )
                      else
                        ...loyaltyState.rewards.map((reward) {
                          final canAfford = points >= reward.pointsCost;
                          return Card(
                            margin: EdgeInsets.only(
                              bottom: ResponsiveUtils.spacing(context, 12),
                            ),
                            child: ListTile(
                              title: Text(
                                reward.title,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${reward.description}\n${reward.pointsCost} points',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 12),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: FilledButton(
                                onPressed: loyaltyState.isRedeeming ||
                                        !canAfford ||
                                        !reward.available
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Redeem reward?'),
                                            content: Text(
                                              'Spend ${reward.pointsCost} points for ${reward.title}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Redeem'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true || !context.mounted) {
                                          return;
                                        }

                                        final success = await ref
                                            .read(loyaltyProvider.notifier)
                                            .redeemReward(reward, points);
                                        if (!context.mounted) return;
                                        if (success) {
                                          SnackBarUtils.showSuccess(
                                            context,
                                            'Reward redeemed successfully!',
                                          );
                                          await ref
                                              .read(profileProvider.notifier)
                                              .refreshProfile();
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F2D82),
                                ),
                                child: Text(canAfford ? 'Redeem' : 'Need pts'),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
