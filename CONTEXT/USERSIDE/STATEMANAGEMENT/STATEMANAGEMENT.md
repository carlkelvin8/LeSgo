# State Management Documentation - Lezgo Project

## Overview

The Lezgo project uses **Riverpod** (flutter_riverpod ^2.5.1) for state management. Riverpod provides a robust, compile-safe, and testable way to manage application state with minimal boilerplate.

## State Management Architecture

### Core Concepts

```text
State Management Flow:
Widget (Consumer) → Provider → UseCase → RepositoryImpl → RemoteDataSource (Dio)
```

## Riverpod Implementation

### Package Used

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
```

### Application Setup

```dart
// main.dart
void main() {
  runApp(const ProviderScope(child: LesgoApp()));
}
```

**Key Point**: The entire app is wrapped in `ProviderScope` to enable provider functionality throughout the widget tree.

## State Management Patterns

### 1. StateNotifier Pattern

The project uses `StateNotifier` for managing complex state with mutations.

#### Structure:

```
provider/
├── feature_name/
│   ├── feature_provider.dart       # Main provider & notifier
│   ├── notifier/
│   │   ├── feature_state.dart      # State class
│   │   └── feature_actions.dart    # Mixin with actions
│   └── controller/
│       └── feature_controller.dart # UI controllers
```

### 2. State Class Pattern

Each feature has an immutable state class with `copyWith` method:

```dart
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool rememberMe;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.rememberMe = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? rememberMe,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  bool get isAuthenticated => user != null;
}
```

**Key Features:**
- Immutable state
- Named parameters for clarity
- Default values
- `copyWith` for creating modified copies
- Computed properties (getters)

### 3. StateNotifier Implementation (UseCase Driven)

Providers act as state orchestrators. They consume pure logic from **Use Cases** rather than invoking APIs or defining data sources themselves.

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthNotifier(this._loginUseCase) : super(AuthState());

  Future<void> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // UI Validation Check first
    if (request.email.isEmpty || request.password.isEmpty) { ... }

    try {
      // Consume the Use Case
      final user = await _loginUseCase(request);
        
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      // The API layer threw an Exception via DTO mapping
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    state = AuthState();
  }
}
```

**Pattern Highlights:**
- Consumes **Use Cases** injected via Riverpod providers.
- Never manually parses JSON or instantiates APIs.
- Update state using `state = state.copyWith(...)`
- Passes extracted Exception messages into the explicit state error parameters for UI `SnackBar` controllers to consume.

### 4. Provider Dependency Injection

Dependencies are chained logically through the application via Riverpod Providers.

```dart
// 1. Base API Provider
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);

// 2. Data Layer Injection
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(dioProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

// 3. Domain UseCase Injection
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(userRepositoryProvider));
});

// 4. Final Notifier Assembly
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(loginUseCaseProvider));
});
```

**Provider Types Used:**
- `StateNotifierProvider` - For complex state with mutations
- `StateProvider` - For simple state values
- `Provider` - For read-only values

## Advanced Pattern: Mixin-Based State Management

For complex features, the project uses mixins to organize state management logic:

### Example: Register Provider

```dart
// register_state.dart
class RegisterState {
  final RegisterRequest data;
  final bool isLoading;
  final String? error;
  final User? registeredUser;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final String? locationName;

  RegisterState({
    RegisterRequest? data,
    this.isLoading = false,
    this.error,
    this.registeredUser,
    this.currentLocation,
    this.selectedLocation,
    this.locationName,
  }) : data = data ?? RegisterRequest();

  RegisterState copyWith({...}) {
    return RegisterState(...);
  }
}
```

```dart
// Mixin for specific functionality
mixin VerificationNotifier on StateNotifier<RegisterState> {
  void updateVerificationCode(String code) {
    state = state.copyWith(
      data: state.data.copyWith(verificationCode: code),
    );
  }
}

mixin TermsNotifier on StateNotifier<RegisterState> {
  void acceptTerms() {
    state = state.copyWith(
      data: state.data.copyWith(termsAccepted: true),
    );
  }
}

mixin SubmitNotifier on StateNotifier<RegisterState> {
  Future<void> submitRegistration() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Validation logic
      if (state.data.firstName.isEmpty || 
          state.data.lastName.isEmpty ||
          !state.data.termsAccepted) {
        throw Exception('Please complete all required fields');
      }
      
      // Create user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: state.data.email,
        name: '${state.data.firstName} ${state.data.lastName}',
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      state = state.copyWith(
        registeredUser: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = RegisterState();
  }
}
```

```dart
// Main notifier combines all mixins
class RegisterNotifier extends StateNotifier<RegisterState> 
    with VerificationNotifier, TermsNotifier, SubmitNotifier {
  
  RegisterNotifier() : super(RegisterState());

  void updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String birthday,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        firstName: firstName,
        lastName: lastName,
        birthday: birthday,
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    // Location logic
  }
}

final registerProvider = 
    StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier();
});
```

**Benefits of Mixin Pattern:**
- Separates concerns by functionality
- Keeps code organized and maintainable
- Easy to test individual functionalities
- Reduces code duplication

## Consumer Widgets

### 1. ConsumerWidget Pattern

```dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: authState.isLoading 
        ? CircularProgressIndicator()
        : LoginForm(
            onSubmit: (email, password) {
              ref.read(authProvider.notifier).login(
                LoginRequest(email: email, password: password)
              );
            },
          ),
    );
  }
}
```

**Key Methods:**
- `ref.watch(provider)` - Listen to state changes, rebuild on update
- `ref.read(provider.notifier)` - Access methods without listening
- `ref.listen(provider, callback)` - Perform side effects on state change

### 2. Consumer Widget (Alternative)

```dart
Consumer(
  builder: (context, ref, child) {
    final authState = ref.watch(authProvider);
    return Text('User: ${authState.user?.name ?? "Guest"}');
  },
)
```

### 3. ConsumerStatefulWidget Pattern

For widgets that need both local and global state:

```dart
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController();
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(labelText: 'Street'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ref.read(registerProvider.notifier).updateAddress(
                  street: _streetController.text,
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

## Provider vs Controller — Key Difference

> [!IMPORTANT]
> This separation is a **core architectural pattern** used across both FRONTEND and RIDERSIDE.

### Quick Summary

| | **Provider** | **Controller** |
|---|---|---|
| **Purpose** | Manages shared state | Controls specific widget behavior |
| **Rebuilds UI** | ✅ Automatically via `ref.watch()` | ❌ Does not automatically rebuild UI |
| **Contains** | State class + StateNotifier + provider definition | Plain class with TextEditingControllers, ImagePickers, etc. |
| **Named** | `*_provider.dart`, `*Notifier`, `*Provider` | `*.controller.notifier.dart`, `*Controllers` |
| **Base class** | `extends StateNotifier<State>` | Plain Dart class (no base class) |
| **Used for** | Global/shared app data, async operations | Form field management, UI-specific orchestration |

### When to use which?

- **Need state that rebuilds UI? → Provider file** (State + StateNotifier + provider def)
- **Need TextEditingControllers, image pickers, snackbar triggers? → Controller file** (plain class)
- **Simple enum/boolean toggle? → `StateProvider` in a provider file**

---

## Controller Pattern

For complex UI interactions, the project uses controller classes:

```dart
// address.controller.notifier.dart
class AddressFormController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();

  void dispose() {
    streetController.dispose();
    cityController.dispose();
    zipController.dispose();
  }

  Future<void> getCurrentLocation(WidgetRef ref) async {
    await ref.read(registerProvider.notifier).getCurrentLocation();
    updateFormFromProvider(ref);
  }

  void updateFormFromProvider(WidgetRef ref) {
    final fields = ref.read(registerProvider.notifier).getFormattedAddressFields();
    streetController.text = fields['street'] ?? '';
    cityController.text = fields['city'] ?? '';
    zipController.text = fields['zip'] ?? '';
  }

  bool validateAndSave(WidgetRef ref) {
    if (formKey.currentState?.validate() ?? false) {
      ref.read(registerProvider.notifier).updateAddress(
        street: streetController.text,
        city: cityController.text,
        zip: zipController.text,
      );
      return true;
    }
    return false;
  }
}
```

## State Management Best Practices

### 1. Immutable State
✅ **Do:**
```dart
state = state.copyWith(isLoading: true);
```

❌ **Don't:**
```dart
state.isLoading = true; // State is immutable!
```

### 2. Loading States
Always include loading states for async operations:
```dart
class FeatureState {
  final bool isLoading;
  final String? error;
  final DataType? data;
}
```

### 3. Error Handling
Consistent error handling pattern:
```dart
Future<void> fetchData() async {
  state = state.copyWith(isLoading: true, error: null);
  
  try {
    final data = await apiCall();
    state = state.copyWith(data: data, isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

### 4. Reset State
Provide reset methods for cleanup:
```dart
void reset() {
  state = FeatureState(); // Reset to initial state
}
```

### 5. Computed Properties
Use getters for derived state:
```dart
class AuthState {
  final User? user;
  
  bool get isAuthenticated => user != null;
  bool get isGuest => user == null;
  String get userName => user?.name ?? 'Guest';
}
```

## Provider Organization

### Feature-Based Structure

```
provider/
├── auth/
│   └── auth_provider.dart
├── main/
│   └── main_provider.dart
├── missions/
│   ├── missions_provider.dart
│   └── missions_state.dart
└── register/
    ├── register_provider.dart
    ├── notifier/
    │   ├── register_state.dart
    │   ├── verification_notifier.dart
    │   ├── terms_notifier.dart
    │   └── submit_notifier.dart
    └── controller/
        ├── personal_info.controller.notifier.dart
        └── address.controller.notifier.dart
```

## Common State Patterns

### 1. Authentication State
```dart
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool rememberMe;
  
  bool get isAuthenticated => user != null;
}
```

### 2. List State
```dart
class MissionsState {
  final List<Mission> missions;
  final bool isLoading;
  final String? error;
  final Mission? selectedMission;
}
```

### 3. Form State
```dart
class RegisterState {
  final RegisterRequest data;
  final Map<String, String> fieldErrors;
  final bool isLoading;
  final String? error;
  final bool isValid;
}
```

### 4. Location State
```dart
class LocationState {
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final String? locationName;
  final bool isLoading;
  final String? error;
}
```

## Testing State Management

### Unit Testing Providers

```dart
void main() {
  test('login updates state correctly', () async {
    final container = ProviderContainer();
    final notifier = container.read(authProvider.notifier);
    
    expect(container.read(authProvider).user, null);
    
    await notifier.login(LoginRequest(
      email: 'test@test.com',
      password: 'password',
    ));
    
    expect(container.read(authProvider).user, isNotNull);
    expect(container.read(authProvider).isAuthenticated, true);
  });
}
```

## Performance Considerations

### 1. Selective Rebuilds
Use `select` to rebuild only when specific properties change:
```dart
final userName = ref.watch(authProvider.select((state) => state.user?.name));
```

### 2. Provider Scope
Keep providers scoped to features, not global when possible.

### 3. Avoid Unnecessary State
Don't put UI-only state in providers (like animation controllers).

## Side Effects with ref.listen

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(authProvider, (previous, next) {
    if (next.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.error!)),
      );
    }
    
    if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  });
  
  return /* widget tree */;
}
```

## Key Advantages of Riverpod

1. **Compile-Time Safety**: Errors caught at compile time, not runtime
2. **No BuildContext Required**: Can read providers outside widgets
3. **Testability**: Easy to test with ProviderContainer
4. **Performance**: Granular rebuilds with select
5. **No Provider Nesting**: Flat provider tree
6. **Type Safety**: Full type inference support

## Migration from Provider to Riverpod

The project exclusively uses Riverpod, but if migrating from Provider:

| Provider | Riverpod |
|----------|----------|
| Provider | Provider |
| ChangeNotifierProvider | StateNotifierProvider |
| Consumer | ConsumerWidget |
| Provider.of(context) | ref.watch(provider) |

## Conclusion

The Lezgo project demonstrates best practices in Riverpod state management:
- Clear state structure with immutability
- Mixin pattern for code organization
- Consistent error handling
- Feature-based provider organization
- Proper use of ConsumerWidget and ref methods

This approach provides a scalable, maintainable, and testable state management solution for the entire application.
