# lesgo_shared

Shared DTOs, models, and constants between LeSGo Customer and Rider apps.

## Usage

In your app's `pubspec.yaml`:

```yaml
dependencies:
  lesgo_shared:
    path: ../packages/lesgo_shared
```

Then import:

```dart
import 'package:lesgo_shared/lesgo_shared.dart';
```

## What's Included

- **DTOs**: Auth, Order, Chat, User, Merchant response/request models
- **Constants**: Order statuses, service types
- **Models**: Shared business entities

## Code Generation

After modifying `@JsonSerializable` classes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Adding New Shared Code

1. Add your DTO/model in the appropriate `lib/src/` subdirectory
2. Export it from `lib/lesgo_shared.dart`
3. Run build_runner if using json_serializable
4. Both apps automatically pick up changes (path dependency)
