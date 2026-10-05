# LeSGo Flutter Architecture

## Repository Pattern

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (screens, widgets, providers)           │
│  - Depends on: Repository interfaces (domain/)             │
│  - NEVER imports datasources directly                      │
└────────────────────────────┬────────────────────────────────┘
                             │ uses
┌────────────────────────────▼────────────────────────────────┐
│  Domain Layer (entities, repository interfaces, use cases)  │
│  - Pure Dart, no Flutter/package dependencies               │
│  - Defines contracts (abstract classes)                     │
└────────────────────────────┬────────────────────────────────┘
                             │ implements
┌────────────────────────────▼────────────────────────────────┐
│  Data Layer (datasources, DTOs, repository implementations) │
│  - Talks to API (Dio), local DB, cache                     │
│  - Registered via @LazySingleton(as: RepositoryInterface)   │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/
├── domain/
│   ├── entities/          # Business objects (User, Order, etc.)
│   ├── repository/        # Abstract interfaces
│   │   ├── auth_repository.dart
│   │   ├── order_repository.dart
│   │   ├── partner_repository.dart
│   │   ├── tracking_repository.dart
│   │   └── user_repository.dart
│   └── use_cases/         # Single-purpose business logic
│       ├── login_usecase.dart
│       └── logout_usecase.dart
├── data/
│   ├── data_source/       # Remote API calls (Dio)
│   ├── repositoryImpl/    # Concrete implementations
│   │   ├── auth_repository_impl.dart
│   │   ├── order_repository_impl.dart
│   │   ├── partner_repository_impl.dart
│   │   ├── tracking_repository_impl.dart
│   │   └── user_repository_impl.dart
│   └── dto/               # JSON serializable data transfer objects
└── presentation/
    ├── provider/           # Riverpod state management
    ├── screens/            # Full page widgets
    └── widgets/            # Reusable UI components
```

## Migration Guide

When refactoring a provider to use repositories:

### Before (direct datasource access):
```dart
class MyProvider extends StateNotifier<MyState> {
  Future<void> loadData() async {
    final datasource = getIt<SomeRemoteDataSource>();
    final result = await datasource.fetchSomething();
    // ...
  }
}
```

### After (repository pattern):
```dart
class MyProvider extends StateNotifier<MyState> {
  final SomeRepository _repository;
  
  MyProvider(this._repository) : super(MyState());
  
  Future<void> loadData() async {
    final result = await _repository.fetchSomething();
    // ...
  }
}
```

### Key benefits:
- **Testable**: Mock the repository interface in tests
- **Swappable**: Add caching, offline mode without changing providers
- **Decoupled**: Providers don't know about Dio, API URLs, DTOs
```

## Current Status

| Repository | Interface | Implementation | Providers Migrated |
|-----------|-----------|----------------|-------------------|
| User | ✅ | ✅ | ✅ AuthProvider |
| Auth | ✅ | ✅ | ⬜ (uses getIt directly) |
| Order | ✅ | ✅ | ⬜ (uses getIt directly) |
| Partner | ✅ | ✅ | ⬜ (uses getIt directly) |
| Tracking | ✅ | ✅ | ⬜ (uses getIt directly) |

Providers will be migrated gradually. New providers should always use repositories.
