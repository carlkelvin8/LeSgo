import 'booking_workflow.dart';

class RiderOrderOpsUtils {
  RiderOrderOpsUtils._();

  /// Rider may cancel before pickup — not after goods/passenger is collected.
  static bool canCancel(String? apiStatus) {
    if (apiStatus == null || BookingWorkflow.isTerminal(apiStatus)) {
      return false;
    }

    final status = apiStatus.toLowerCase();
    return status == 'accepted' ||
        status == 'ready_for_pickup' ||
        status == 'driver_arrived_at_pickup' ||
        status == 'in_progress';
  }
}
