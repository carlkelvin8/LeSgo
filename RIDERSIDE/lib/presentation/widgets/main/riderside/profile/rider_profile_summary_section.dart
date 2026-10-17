import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../screens/main/riderside/views/rider_mission_view.dart';
import '../more/rider_more_components.dart';
import 'profile_panel.dart';
import 'profile_action_tile.dart';

class RiderProfileSummarySection extends ConsumerWidget {
  const RiderProfileSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final missions = ref.watch(riderMissionProvider);
    final order = ref.watch(riderOrdersProvider).activeOrder;
    String t(String key) => AppLocalization.translate(key, lang);
    final inProgress = missions.missions
        .where((m) => !m.isCompleted && m.currentProgress > 0)
        .length;
    final claimable = missions.missions
        .where((m) => m.isCompleted && !m.rewardClaimed)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoreSectionHeading(title: t('rp_on_the_road')),

        // Alert cards
        if (order != null) ...[
          _PulsingStatusCard(
            icon: Icons.delivery_dining_rounded,
            title: t('active_delivery'),
            message: '#${order.id} · ${order.status.replaceAll('_', ' ')}',
            color: const Color(0xFF5F2D82),
            bg: profileDark(context)
                ? const Color(0xFF1E1530)
                : const Color(0xFFF3EEFF),
            onTap: () => ref
                .read(riderNavProvider.notifier)
                .navigateTo(RiderNavType.bookings),
          ),
          const SizedBox(height: 10),
        ],
        if (claimable > 0 || inProgress > 0) ...[
          _PulsingStatusCard(
            icon: claimable > 0
                ? Icons.card_giftcard_rounded
                : Icons.flag_rounded,
            title: t(
              claimable > 0 ? 'mission_reward_ready' : 'missions_in_progress',
            ),
            message: t(claimable > 0 ? 'rp_rewards_count' : 'rp_missions_count')
                .replaceAll(
                  '{count}',
                  '${claimable > 0 ? claimable : inProgress}',
                ),
            color: claimable > 0
                ? const Color(0xFF16A34A)
                : const Color(0xFF5F2D82),
            bg: profileDark(context)
                ? const Color(0xFF0F2018)
                : const Color(0xFFECFDF5),
            pulse: claimable > 0,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const RiderMissionView(includeBottomNavPadding: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Document verification quick link
        MoreMenuGroup(
          children: [
            ProfileActionTile(
              icon: Icons.verified_user_outlined,
              title: t('document_verification'),
              subtitle: t('rp_documents_hint'),
              onTap: () => AppRouter.push(context, MainRoutes.riderDocuments),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Pulsing status card ──────────────────────────────────────────────────────
class _PulsingStatusCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final bool pulse;

  const _PulsingStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.bg,
    required this.onTap,
    this.pulse = false,
  });

  @override
  State<_PulsingStatusCard> createState() => _PulsingStatusCardState();
}

class _PulsingStatusCardState extends State<_PulsingStatusCard>
    with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _anim.repeat(reverse: true);
    } else {
      _anim.value = .5;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_anim, _press]),
      builder: (_, __) => Transform.scale(
        scale: 1.0 - .02 * _press.value,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.selectionClick();
            _press.forward();
          },
          onTapUp: (_) => _press.reverse(),
          onTapCancel: () => _press.reverse(),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.color.withValues(alpha: .25 + .12 * _anim.value),
                width: widget.pulse ? 1.5 : 1,
              ),
              boxShadow: [
                if (widget.pulse)
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: .12 + .10 * _anim.value,
                    ),
                    blurRadius: 16 + 8 * _anim.value,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Row(
              children: [
                // Icon with pulsing container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: .12 + .06 * _anim.value,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11.5,
                          color: widget.color.withValues(alpha: .75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: widget.color.withValues(alpha: .60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
