import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to trigger a silent inbox refresh from the main screen timer.
final riderInboxRefreshSignalProvider = StateProvider<int>((ref) => 0);
