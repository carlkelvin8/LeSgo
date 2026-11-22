import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../domain/entities/missions/mission.dart';
import '../../provider/missions/missions_provider.dart';

class MissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final VoidCallback? onTap;

  const MissionCard({super.key, required this.mission, this.onTap});

  @override
  ConsumerState<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<MissionCard> {
  bool _claiming = false;

  Future<void> _claimReward() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      await ref.read(missionsProvider.notifier).claimMission(widget.mission.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reward claimed! ${Money.format(widget.mission.rewardValue, decimals: 0)} ${widget.mission.rewardType}',
            ),
            backgroundColor: const Color(0xFF22A060),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMapper.message(
                e,
                fallbackEn: 'Failed to claim reward.',
                fallbackTl: 'Hindi ma-claim ang reward.',
              ),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final theme = Theme.of(context);
    final accent = AppColors.buttonFill(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final (icon, color) = _missionStyle(mission.missionType);
    final tone = AppColors.accent(context, color);
    final progress = '${mission.currentProgress}/${mission.goalTarget}';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: BorderSide(
        color: AppColors.border(context, const Color(0xFFE8DFED)),
      ),
    );

    return Material(
      color: AppColors.surface(context, Colors.white),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: tone, size: 23),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (mission.description case final description?
                            when description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 4),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        size: 17,
                        color: accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: mission.progressPercentage,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                      color: accent,
                      backgroundColor: accent.withValues(alpha: .11),
                      semanticsLabel: 'Mission progress',
                      semanticsValue:
                          '${mission.currentProgress} of ${mission.goalTarget}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progress,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (mission.rewardValue > 0 ||
                  mission.isCompleted ||
                  mission.rewardClaimed) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (mission.rewardValue > 0)
                      _MissionBadge(
                        icon: Icons.confirmation_number_outlined,
                        label:
                            '${Money.format(mission.rewardValue, decimals: 0)} ${mission.rewardType}',
                        color: accent,
                      ),
                    if (mission.rewardClaimed)
                      _MissionBadge(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Claimed',
                        color: muted,
                      )
                    else if (mission.isCompleted)
                      FilledButton(
                        onPressed: mission.userId == 0 || _claiming
                            ? null
                            : _claimReward,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: AppColors.onButton(context),
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(_claiming ? 'Claiming…' : 'Claim reward'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

(IconData, Color) _missionStyle(String type) {
  if (type.contains('ride')) {
    return (Icons.directions_car_outlined, const Color(0xFF006D61));
  }
  if (type.contains('refer')) {
    return (Icons.group_add_outlined, const Color(0xFF3259A6));
  }
  if (type == 'app_review') {
    return (Icons.star_border_rounded, const Color(0xFF895400));
  }
  return (Icons.flag_outlined, const Color(0xFF5F2D82));
}

class _MissionBadge extends StatelessWidget {
  const _MissionBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
