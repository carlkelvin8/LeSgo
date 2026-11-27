import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/referral_remote_datasource.dart';
import '../../../provider/main/referral/referral_provider.dart';
import '../../../widgets/common/retry_widget.dart';
import '../../../widgets/profile/invite_friends_sheet.dart';

class ReferralDashboardScreen extends ConsumerWidget {
  const ReferralDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(referralDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.surface(context, const Color(0xFFF8F7FB)),
      appBar: AppBar(
        title: const Text('Referral rewards'),
        backgroundColor: AppColors.surface(context, const Color(0xFFF8F7FB)),
        surfaceTintColor: Colors.transparent,
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent(context, const Color(0xFF5F2D82)),
              ),
            )
          : state.error != null &&
                state.referralCode.isEmpty &&
                state.invitesSent == 0
          ? RetryWidget(
              message: state.error!,
              onRetry: () =>
                  ref.read(referralDashboardProvider.notifier).loadDashboard(),
            )
          : RefreshIndicator(
              color: AppColors.accent(context, Color(0xFF5F2D82)),
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
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Invite more friends'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buttonFill(context),
                      foregroundColor: AppColors.onButton(context),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                      'No referral rewards yet. Share your code to start earning.',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    )
                  else
                    _RewardsList(rewards: state.recentRewards),
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
      childAspectRatio: 1.45,
      children: [
        _StatTile(
          icon: Icons.send_rounded,
          label: 'Invites sent',
          value: '${state.invitesSent}',
        ),
        _StatTile(
          icon: Icons.group_rounded,
          label: 'Friends joined',
          value: '${state.friendsJoined}',
        ),
        _StatTile(
          icon: Icons.hourglass_top_rounded,
          label: 'Pending rewards',
          value: '${state.pendingRewards}',
        ),
        _StatTile(
          icon: Icons.stars_rounded,
          label: 'Points earned',
          value: '${state.pointsEarned}',
          highlight: true,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    final fg = highlight ? Colors.white : accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: highlight ? null : AppColors.surface(context, Colors.white),
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0xFF3B1A56), Color(0xFF7B2DA8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF5F2D82,
            ).withValues(alpha: highlight ? 0.25 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: highlight ? Colors.white70 : accent, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 26),
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: highlight
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.foreground(context, Colors.grey[600]!),
                ),
              ),
            ],
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
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR CODE',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground(
                      context,
                      const Color(0xFF8B729C),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code.isEmpty ? 'Getting your code…' : code,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 22),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy code',
            onPressed: code.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    SnackBarUtils.showSuccess(context, 'Referral code copied!');
                  },
            icon: Icon(Icons.copy_rounded, color: accent),
          ),
        ],
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  const _RewardsList({required this.rewards});

  final List<ReferralRewardDto> rewards;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    if (rewards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: muted, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No rewards yet. Share your code and earn points when your friends order.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  height: 1.4,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rewards.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 64,
                color: AppColors.border(context, const Color(0xFFECE5F2)),
              ),
            _RewardRow(reward: rewards[i]),
          ],
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward});

  final ReferralRewardDto reward;

  @override
  Widget build(BuildContext context) {
    final status = reward.status.toLowerCase();
    final done =
        status == 'paid' ||
        status == 'completed' ||
        status == 'credited' ||
        status == 'earned';
    final tone = done ? const Color(0xFF2E9E5B) : const Color(0xFFEF8A1B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.hourglass_top_rounded,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${capitalizeReferralStatus(reward.status)}'
                  '${reward.date != null ? ' • ${formatReferralRewardDate(reward.date!)}' : ''}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${reward.points} pts',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
