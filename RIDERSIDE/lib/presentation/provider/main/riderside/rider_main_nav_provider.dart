import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum defining the navigation tabs for the Rider app
enum RiderNavType { bookings, history, inbox, profile, wallet, mission }

/// StateNotifier that maintains a navigation stack.
/// - [state.last] is always the currently visible tab.
/// - Tapping a new tab pushes it onto the stack.
/// - Back gesture pops the stack; if only bookings remains, the app exits.
class RiderNavNotifier extends StateNotifier<List<RiderNavType>> {
  RiderNavNotifier() : super(const [RiderNavType.bookings]);

  RiderNavType get current => state.last;

  void navigateTo(RiderNavType type) {
    if (state.last == type) return; // already on this tab, no-op
    // Tapping Bookings always resets the stack to root
    if (type == RiderNavType.bookings) {
      state = const [RiderNavType.bookings];
      return;
    }
    // Remove any existing occurrence of this tab, then push to top
    final filtered = state.where((t) => t != type).toList();
    state = [...filtered, type];
  }

  /// Returns true if a tab was popped (back handled internally).
  /// Returns false when already at root so the system can close the app.
  bool pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
      return true;
    }
    return false;
  }
}

final riderNavProvider =
    StateNotifierProvider<RiderNavNotifier, List<RiderNavType>>(
  (ref) => RiderNavNotifier(),
);
