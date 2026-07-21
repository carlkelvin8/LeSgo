# Migrating DTOs to lesgo_shared

## What's Ready Now (no build_runner needed)

These can be used immediately in both FRONTEND and RIDERSIDE:

```dart
import 'package:lesgo_shared/lesgo_shared.dart';

// Order status constants
if (OrderStatuses.isActive(order.status)) { ... }
if (OrderStatuses.isTerminal(order.status)) { ... }

// Order status enum
final status = OrderStatus.fromString(apiResponse['status']);
print(status.label); // "Driver Arrived"
print(status.toApiString()); // "driver_arrived"

// Service types
if (order.serviceType == ServiceTypes.lesEat) { ... }
print(ServiceTypes.label(ServiceTypes.lesBuy)); // "LesBuy"
```

## What Needs build_runner (DTOs with JSON serialization)

These files exist in `lib/src/dto/` but require code generation:

```bash
cd packages/lesgo_shared
dart run build_runner build --delete-conflicting-outputs
```

After running, you can also export:
- `SharedUserDto`
- `SharedPartnerDto`
- `SharedMenuItemDto`
- `SharedMessageDto`
- `OtpResponseDto`
- `LoginResponseDto`

## Migration Steps for a DTO

1. Identify a duplicated DTO (exists in both FRONTEND and RIDERSIDE)
2. Compare both versions — pick the more complete one
3. Add it to `packages/lesgo_shared/lib/src/dto/`
4. Export from `lib/lesgo_shared.dart`
5. Run build_runner in the shared package
6. In FRONTEND/RIDERSIDE: replace the local import with shared package import
7. Delete the local duplicate

## Example: Replacing local OrderStatuses

### Before (FRONTEND):
```dart
// Scattered magic strings
if (order.status == 'driver_assigned') { ... }
if (order.status == 'completed' || order.status == 'cancelled') { ... }
```

### After (shared package):
```dart
import 'package:lesgo_shared/lesgo_shared.dart';

if (order.status == OrderStatuses.driverAssigned) { ... }
if (OrderStatuses.isTerminal(order.status)) { ... }
```

## Rules

- Never modify shared DTOs without checking both apps
- The shared package should have no Flutter dependency (pure Dart only)
- Keep json_annotation as the only runtime dependency
- All shared code must work for both Customer and Rider contexts
