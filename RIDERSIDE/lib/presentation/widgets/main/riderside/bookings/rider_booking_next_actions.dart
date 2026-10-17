import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/booking_workflow.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/app_localization.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../profile/profile_panel.dart';

class RiderBookingNextActions extends ConsumerWidget {
  final BookingCategory category;
  final String? apiStatus;
  final bool isUpdating;
  final bool awaitingProof;
  final void Function(BookingStatus status)? onAction;

  const RiderBookingNextActions({
    super.key,
    required this.category,
    required this.apiStatus,
    this.isUpdating = false,
    this.awaitingProof = false,
    this.onAction,
  });

  IconData _iconFor(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'camera':
        return Icons.camera_alt_outlined;
      case 'location_on':
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final actions = BookingWorkflow.nextActions(
      apiStatus: apiStatus,
      category: category,
      awaitingProof: awaitingProof,
    );
    final terminal = BookingWorkflow.isTerminal(apiStatus);
    final cancelled = apiStatus == 'cancelled';
    final dark = profileDark(context);
    final terminalColor = cancelled
        ? (dark ? const Color(0xFFFFB4BC) : const Color(0xFFB63845))
        : (dark ? const Color(0xFF8CD7B4) : const Color(0xFF23774F));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (terminal)
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            decoration: BoxDecoration(
              color: terminalColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  cancelled
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  color: terminalColor,
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Text(
                    AppLocalization.translate(
                      cancelled ? 'order_cancelled' : 'order_finished',
                      lang,
                    ),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w600,
                      color: terminalColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (actions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: profileMuted(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalization.translate('waiting_next_step', lang),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13,
                      height: 1.4,
                      color: profileMuted(context),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...actions.map((action) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 10),
              ),
              child: Material(
                color: const Color(0xFF5F2D82),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: isUpdating || onAction == null
                      ? null
                      : () => onAction!(action.targetStatus),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 16),
                      vertical: ResponsiveUtils.spacing(context, 14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(action.iconName),
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.title,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    16,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.spacing(context, 4),
                              ),
                              Text(
                                action.subtitle,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    12,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUpdating)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
