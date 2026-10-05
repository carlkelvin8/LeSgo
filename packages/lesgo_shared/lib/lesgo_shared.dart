/// Shared DTOs, models, and constants for LeSGo apps.
///
/// Usage:
/// ```dart
/// import 'package:lesgo_shared/lesgo_shared.dart';
/// ```
///
/// For DTOs that need json_serializable, run:
/// ```bash
/// cd packages/lesgo_shared
/// dart run build_runner build --delete-conflicting-outputs
/// ```
library lesgo_shared;

// Constants (no code generation needed — use immediately)
export 'src/constants/order_statuses.dart';
export 'src/constants/service_types.dart';

// Order status enum (no code generation needed)
export 'src/dto/order/order_status.dart';
