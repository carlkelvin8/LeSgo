import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the Rider's "ON DUTY" / "OFF DUTY" toggle state on the Bookings view.
final riderDutyProvider = StateProvider<bool>((ref) => true);
