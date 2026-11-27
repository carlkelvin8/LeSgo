import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/booking_workflow.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/app_localization.dart';
import '../../../../../../domain/entities/rider_booking.dart';

const _violet = Color(0xFF5F2D82);

/// Progress card for a booking: a stepper where only the *next* step is
/// violet, finished steps are gray, and a single big button for what to do now.
class RiderBookingNextActions extends ConsumerWidget {
  final BookingCategory category;
  final String? apiStatus;
  final bool isUpdating;
  final bool awaitingProof;
  final String? statusLabel;
  final void Function(BookingStatus status)? onAction;

  const RiderBookingNextActions({
    super.key,
    required this.category,
    required this.apiStatus,
    this.isUpdating = false,
    this.awaitingProof = false,
    this.statusLabel,
    this.onAction,
  });

  IconData _iconFor(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.inventory_2_outlined;
      case 'camera':
        return Icons.photo_camera_outlined;
      case 'location_on':
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final actions = BookingWorkflow.nextActions(
      apiStatus: apiStatus,
      category: category,
      awaitingProof: awaitingProof,
    );
    final terminal = BookingWorkflow.isTerminal(apiStatus);
    final stepCount = BookingWorkflow.stepLabels.length;
    final step = apiStatus != null
        ? BookingWorkflow.workflowStepIndex(apiStatus!)
        : 0;
    // Index of the step the rider is working on now (the highlighted one).
    // Everything before it is done (gray); when finished, all are done.
    final currentIndex = terminal ? stepCount : step + 1;

    final cardColor = dark ? const Color(0xFF1E1730) : Colors.white;
    final borderColor = dark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2);
    final titleColor = dark ? Colors.white : const Color(0xFF1A0A2E);

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 18)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: dark ? .10 : .06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              if (statusLabel != null && statusLabel!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _violet.withValues(alpha: dark ? .30 : .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel!.replaceAll('\n', ' ').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 10.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                      color: dark ? const Color(0xFFD9C2F5) : _violet,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 20)),
          _Stepper(currentIndex: currentIndex, dark: dark),
          SizedBox(height: ResponsiveUtils.spacing(context, 22)),
          if (terminal)
            _InfoBanner(
              icon: Icons.check_circle_rounded,
              text: AppLocalization.translate('order_finished', lang),
              dark: dark,
            )
          else if (actions.isEmpty)
            _InfoBanner(
              icon: Icons.hourglass_top_rounded,
              text: AppLocalization.translate('waiting_next_step', lang),
              dark: dark,
            )
          else ...[
            Text(
              'NEXT STEP',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 10.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: dark ? const Color(0xFF9A85B8) : const Color(0xFFAA90C0),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            for (final action in actions)
              Padding(
                padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 10)),
                child: _ActionButton(
                  icon: _iconFor(action.iconName),
                  title: action.title,
                  subtitle: action.subtitle,
                  loading: isUpdating,
                  onTap: isUpdating || onAction == null
                      ? null
                      : () => onAction!(action.targetStatus),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dark;
  const _InfoBanner(
      {required this.icon, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2140) : const Color(0xFFF4F2F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: dark ? const Color(0xFF9A85B8) : Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B3FA6), _violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _violet.withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: Colors.white.withValues(alpha: .85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Done = gray check, current = violet (glowing), upcoming = light gray.
class _Stepper extends StatelessWidget {
  final int currentIndex;
  final bool dark;
  const _Stepper({required this.currentIndex, required this.dark});

  @override
  Widget build(BuildContext context) {
    final labels = BookingWorkflow.stepLabels;
    final doneColor = dark ? const Color(0xFF4A4060) : const Color(0xFFB8B2C4);
    final todoColor = dark ? const Color(0xFF2A2140) : const Color(0xFFEDEAF2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final before = i ~/ 2; // connector after step `before`
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: before < currentIndex ? doneColor : todoColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }
        final index = i ~/ 2;
        final isDone = index < currentIndex;
        final isCurrent = index == currentIndex;
        return SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? _violet
                      : (isDone ? doneColor : todoColor),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: _violet.withValues(alpha: .45),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 20, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? Colors.white
                                : (dark
                                    ? const Color(0xFF6E6486)
                                    : const Color(0xFFA9A2B8)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  height: 1.15,
                  color: isCurrent
                      ? (dark ? const Color(0xFFD9C2F5) : _violet)
                      : (dark ? Colors.white38 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
