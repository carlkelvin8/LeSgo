# Architecture Documentation - Lezgo Project

## Overview

The Lezgo project (both FRONTEND and RIDERSIDE applications) follows **Clean Architecture** principles with a clear separation of concerns across three main layers. This architecture promotes maintainability, testability, and scalability.

## Architecture Pattern

### 5-Layer Clean Architecture

```text
lib/
├── presentation/    # UI Layer (Widgets, Screens, Providers)
├── domain/         # Business Logic Layer (Entities, Use Cases, Repository Interfaces)
├── data/           # Data Layer (Data Sources, Repository Implementations, DTOs)
└── core/           # Shared utilities, extensions, and network constants
```

## Layer Breakdown

### 1. Presentation Layer (`lib/presentation/`)

The presentation layer is responsible for displaying data and handling user interactions.

#### Structure:
```
presentation/
├── provider/        # State management (Riverpod StateNotifiers)
│   ├── auth/
│   ├── main/
│   ├── missions/
│   └── register/
├── screens/         # Full-page UI components
│   ├── auth/
│   └── main/
└── widgets/         # Reusable UI components
    ├── auth/
    ├── booking/
    ├── drawer/
    ├── faq/
    ├── global/
    ├── home/
    ├── inbox/
    ├── lespay/
    ├── location/
    ├── missions/
    ├── profile/
    └── transactions/
```

**Key Characteristics:**
- **Screens**: Complete page views that compose multiple widgets
- **Widgets**: Reusable, composable UI components organized by feature
- **Providers**: State management using Riverpod's StateNotifier pattern
- **Separation**: UI logic is separated from business logic

### 2. Domain Layer (`lib/domain/`)

The domain layer contains pure business logic and contracts. It is completely decoupled from any network or API dependencies like `Dio`.

#### Structure:
```text
domain/
├── entities/        # Business models (pure, clean objects)
├── use_cases/       # Executable logic units calling repositories
└── repositories/    # Abstract interfaces defining contracts
```

**Key Characteristics:**
- **Entities**: Pure logic objects. No `fromJson` or JSON handling natively.
- **Use Cases**: Act as mediators between Providers and Repositories.
- **Repositories**: Just `interface` contracts that the data layer must fulfill.

### 3. Data Layer (`lib/data/`)

The data layer is responsible for executing API requests, bridging HTTP frameworks like `Dio`, and mapping DTOs (Data Transfer Objects) back into pure Domain entities.

#### Structure:
```text
data/
├── data_source/     # Remote and Local data sources executing direct queries
│   └── dto/         # JSON-serializable models mirroring API payloads
└── repositoryImpl/  # Concrete implementations mapping DTOs -> Entities
```

**Key Characteristics:**
- **Data Source**: Uses `Dio` for remote networking, catching HTTP errors. Takes Request DTOs, returns Response DTOs.
- **DTOs**: Network-specific objects implementing `toJson` and `fromJson`.
- **Repository Implementations**: Implement the `domain` contracts. Take pure Entities, convert them to DTOs, pass to the data source, and convert the returning Response DTOs back into pure Entities.

### 4. Core Layer (`lib/core/`)

**Key Characteristics:**
- **Entities**: Represent core business objects with plain Dart classes
- **Pure Dart**: No Flutter dependencies
- **Immutability**: Most entities use `copyWith()` pattern for immutability
- **Data Contracts**: Define the structure of data flowing through the app

### 3. Core Layer (`lib/core/`)

The core layer provides shared functionality across the application.

#### Structure:
```
core/
├── constants/        # App-wide constants
│   ├── api_constants.dart
│   └── routers/      # Navigation configuration
│       ├── app_router.dart
│       ├── auth/
│       ├── booking/
│       ├── main/
│       └── register/
└── utils/            # Utility functions
    └── responsive_utils.dart
```

**Key Characteristics:**
- **Constants**: API endpoints, strings, and configuration values
- **Routers**: Centralized navigation logic with route definitions
- **Utils**: Helper functions (responsive design, formatting, etc.)

## Project Organization

### Application Entry Point

```dart
// main.dart
void main() {
  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: LoginRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
```

**Key Points:**
- Uses `ProviderScope` to enable Riverpod state management
- Centralized routing through `AppRouter.onGenerateRoute`
- Clean separation of navigation logic

## Routing Architecture

### Modular Router Pattern

The routing system is modular and feature-based:

```
routers/
├── app_router.dart           # Main router aggregator
├── auth/
│   ├── auth_router.dart
│   └── auth_routes.dart
├── register/
│   ├── register_router.dart
│   └── register_routes.dart
├── main/
│   ├── main_router.dart
│   └── main_routes.dart
└── booking/
    ├── booking_router.dart
    └── booking_routes.dart
```

**Benefits:**
- Feature-based route organization
- Easy to add/remove entire feature sets
- Type-safe route names as string constants
- Centralized navigation logic

### Router Pattern Example

```dart
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final loginRoute = LoginRouter.onGenerateRoute(settings);
    if (loginRoute != null) return loginRoute;
    
    final registerRoute = RegisterRouter.onGenerateRoute(settings);
    if (registerRoute != null) return registerRoute;
    
    final mainRoute = MainRouter.onGenerateRoute(settings);
    if (mainRoute != null) return mainRoute;
    
    return _defaultRoute(settings);
  }
}
```

## Data Flow

### Unidirectional Data Flow

```
User Action → Widget → Provider (StateNotifier)
                          ↓
                    State Update
                          ↓
                    UI Rebuild
```

1. **User Interaction**: User interacts with a widget
2. **Action Dispatch**: Widget calls method on Provider
3. **State Update**: Provider updates state
4. **UI Rebuild**: Widget rebuilds with new state

## Key Architectural Benefits

### 1. Separation of Concerns
- UI logic separated from business logic
- Easy to test individual components
- Clear boundaries between layers

### 2. Scalability
- Feature-based organization
- Easy to add new features without affecting existing code
- Modular router system

### 3. Maintainability
- Clear file structure
- Consistent patterns across features
- Reusable components

### 4. Testability
- Domain entities are pure Dart (easy to test)
- Providers can be tested in isolation
- Widgets can be tested with mock providers

## Feature Organization Pattern

Each feature follows a consistent structure:

```
feature_name/
├── entities/         (domain layer)
├── provider/         (state management)
├── screens/          (full pages)
└── widgets/          (reusable components)
```

**Example: Authentication Feature**
```
auth/
├── domain/entities/auth/
│   ├── login/
│   │   └── login_request.dart
│   └── register/
│       └── register_request.dart
├── presentation/provider/auth/
│   └── auth_provider.dart
├── presentation/screens/auth/
│   └── login_screen.dart
└── presentation/widgets/auth/
    ├── login/
    └── register/
```

## Design Principles Applied

### 1. Single Responsibility Principle (SRP)
- Each class/file has one clear purpose
- Widgets are small and focused
- Providers manage specific feature states

### 2. Dependency Inversion Principle (DIP)
- UI depends on abstractions (providers), not concrete implementations
- Domain layer has no Flutter dependencies

### 3. Open/Closed Principle (OCP)
- Easy to extend with new features
- Existing code rarely needs modification

## Multi-App Architecture

The project contains multiple Flutter applications:

```
lezgo/
├── FRONTEND/      # User-facing app
├── RIDERSIDE/     # Rider/Merchant app
├── BACKEND/       # Backend services
└── CONTEXT/       # Shared documentation
```

**Shared Patterns:**
- Both apps follow the same architectural pattern
- Consistent folder structure
- Similar state management approach
- Code reusability through shared patterns

## Technology Stack

- **Framework**: Flutter 3.8+
- **Language**: Dart
- **State Management**: Riverpod (flutter_riverpod: ^2.5.1)
- **Architecture**: Clean Architecture with feature-based organization
- **Navigation**: Named routes with modular router pattern

## Best Practices

1. **Keep Widgets Small**: Break down complex UIs into smaller, reusable widgets
2. **Use Const Constructors**: Improve performance with const widgets where possible
3. **Immutable State**: Use `copyWith()` pattern for state updates
4. **Feature Organization**: Group related files by feature, not by type
5. **Responsive Design**: Use `ResponsiveUtils` for consistent sizing across devices
6. **Type Safety**: Leverage Dart's strong typing for safer code

## Future Considerations

### Potential Enhancements:
1. **Data Layer**: Add a separate data layer for API calls and local storage
2. **Use Cases**: Introduce use case classes for complex business logic
3. **Repositories**: Abstract data sources with repository pattern
4. **Dependency Injection**: Consider using Riverpod's provider pattern more extensively
5. **Testing**: Expand test coverage with unit, widget, and integration tests

## Conclusion

The Lezgo project demonstrates a well-structured Clean Architecture implementation in Flutter. The clear separation of concerns, modular routing, and consistent patterns make it maintainable and scalable for future growth.
