/// Shared polling cadence tuned to reduce battery use vs. fixed 5s timers.
class PollingIntervals {
  PollingIntervals._();

  /// Waiting for merchant/restaurant confirmation.
  static const waiting = Duration(seconds: 15);

  /// Order status screens (non-live-map).
  static const orderStatus = Duration(seconds: 12);

  /// Live driver location + status (single shared poller).
  static const liveTracking = Duration(seconds: 12);

  /// Realtime notification poll for chat (primary refresh trigger).
  static const chatRealtime = Duration(seconds: 5);

  /// Open chat thread message refresh (fallback).
  static const chatMessages = Duration(seconds: 30);

  /// Server ETA refresh fallback during live map tracking.
  static const liveEta = Duration(seconds: 30);
}
