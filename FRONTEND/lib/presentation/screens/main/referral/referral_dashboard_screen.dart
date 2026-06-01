import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/referral/referral_provider.dart';
import '../../../widgets/common/retry_widget.dart';
import '../../../widgets/profile/invite_friends_sheet.dart';

class ReferralDashboardScreen extends ConsumerWidget {
  const ReferralDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(referralDashboardProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Referral rewards'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : state.error != null && state.referralCode.isEmpty
              ? RetryWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(referralDashboardProvider.notifier).loadDashboard(),
                )
              : RefreshIndicator(
                  color: const Color(0xFF5F2D82),
                  onRefresh: () =>
                      ref.read(referralDashboardProvider.notifier).loadDashboard(),
                  child: ListView(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                    children: [
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      _StatGrid(state: state),
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                      _ReferralCodeCard(code: state.referralCode),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      FilledButton.icon(
                        onPressed: () => InviteFriendsSheet.show(
                          context,
                          referralCode: state.referralCode,
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Invite more friends'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2D82),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      Text(
                        'Recent rewards',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      if (state.recentRewards.isEmpty)
                        Text(
                          state.fromApi
                              ? 'No referral rewards yet. Share your code to start earning.'
                              : 'Reward history will appear here once friends join.',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey[600],
                          ),
                        )
                      else
                        ...state.recentRewards.map(
                          (reward) => Card(
                            child: ListTile(
                              title: Text(reward.title),
                              subtitle: Text(
                                '${reward.status} • ${reward.points} pts',
                              ),
                              trailing: reward.date != null
                                  ? Text(
                                      reward.date!,
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.fontSize(
                                          context,
                                          11,
                                        ),
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});

  final ReferralDashboardState state;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatTile(label: 'Invites sent', value: '${state.invitesSent}'),
        _StatTile(label: 'Friends joined', value: '${state.friendsJoined}'),
        _StatTile(label: 'Pending rewards', value: '${state.pendingRewards}'),
        _StatTile(label: 'Points earned', value: '${state.pointsEarned}'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5F2D82),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              SnackBarUtils.showSuccess(context, 'Referral code copied!');
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }
}
