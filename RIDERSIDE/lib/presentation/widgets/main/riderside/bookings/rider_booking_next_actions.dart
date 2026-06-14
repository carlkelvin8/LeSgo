import 'package:flutter/material.dart';
import '../../../../../../core/utils/booking_workflow.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/rider_booking.dart';

class RiderBookingNextActions extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final actions = BookingWorkflow.nextActions(
      apiStatus: apiStatus,
      category: category,
      awaitingProof: awaitingProof,
    );
    final step = apiStatus != null
        ? BookingWorkflow.workflowStepIndex(apiStatus!)
        : 0;
    final terminal = BookingWorkflow.isTerminal(apiStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepProgress(currentStep: terminal ? 3 : step),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        if (terminal)
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: Text(
                    'This order is finished. Great job!',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (actions.isEmpty)
          Text(
            'Waiting for the next step…',
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: Colors.grey.shade600,
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
                      vertical: ResponsiveUtils.spacing(context, 18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(action.iconName),
                          color: Colors.white,
                          size: 28,
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
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 16),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                  height:
                                      ResponsiveUtils.spacing(context, 4)),
                              Text(
                                action.subtitle,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 12),
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
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
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

class _StepProgress extends StatelessWidget {
  final int currentStep;

  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(BookingWorkflow.stepLabels.length, (index) {
        final isDone = index <= currentStep;
        final isActive = index == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF5F2D82)
                            : Colors.grey.shade300,
                        border: isActive
                            ? Border.all(
                                color: const Color(0xFFC320D6), width: 2)
                            : null,
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      BookingWorkflow.stepLabels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 8),
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isDone
                            ? const Color(0xFF5F2D82)
                            : Colors.grey.shade500,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < BookingWorkflow.stepLabels.length - 1)
                Container(
                  width: 12,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: index < currentStep
                      ? const Color(0xFF5F2D82)
                      : Colors.grey.shade300,
                ),
            ],
          ),
        );
      }),
    );
  }
}
