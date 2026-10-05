import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recreated whenever the signed-in customer changes or logs out. User-scoped
/// providers watch this value so cached state from one account cannot survive
/// into another session.
final userSessionEpochProvider = StateProvider<int>((ref) => 0);
