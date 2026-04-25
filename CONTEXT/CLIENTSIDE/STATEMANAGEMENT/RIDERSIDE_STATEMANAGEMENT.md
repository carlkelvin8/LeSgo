# State Management Documentation - Lezgo RIDERSIDE

## Overview

The RIDERSIDE application uses **Riverpod** (flutter_riverpod ^2.5.1) for state management, implementing a **mixed state approach** that fits its current scope. The state management strategy is designed to scale as the application grows from simple state providers to more complex StateNotifier patterns.

## State Management Philosophy

### Current Approach: Mixed State Patterns

The RIDERSIDE app uses **three levels of Riverpod state management** based on complexity:

- **StateProvider** — For simple boolean/enum state (auth view switching, terms acceptance, merchant nav)
- **StateNotifier<List<T>>** — For stack-based navigation state with push/pop behavior (rider main nav)
- **StateNotifier + State class** — For complex feature state (registration info with uploads, phone verification with OTP)

### Current Architecture

```
Simple State:        StateProvider (auth view, terms checkbox, merchant nav, duty toggle)
Stack Navigation:    StateNotifier<List<RiderNavType>> (rider main nav — push/pop with dedup)
Complex State:       StateNotifierProvider + State class (registration, phone verification, history)
Future:              StateNotifierProvider + Use Cases (full Clean Architecture with API)
```

## Merchantside Menu State (Latest)

Merchantside menu forms now use a clearer split between provider state and form controller lifecycle.

### Menu Item Form Provider

`merchant_menu_item_form_provider.dart` now uses a typed family key:

- `MerchantMenuItemFormInput`
  - `MerchantMenuItemFormInput.add()` for add screen defaults
  - `MerchantMenuItemFormInput.edit(initialItem)` for edit screen initialization

Benefits:
- No ad hoc `Map` payload creation in screen `build()`
- Stable provider identity per screen instance
- Initialization semantics are explicit and type-safe

### Add Category Provider Simplification

`merchantAddCategoryFormProvider` changed from `family<String?>` to plain `StateNotifierProvider`.

Benefits:
- Removes nullable family-key plumbing (`provider(null)`)
- Cleaner `watch/read/listen` usage in screen

### Controller Responsibilities (Menu Forms)

Controllers own `TextEditingController` and `formKey` lifecycle only:

- `MerchantMenuItemFormController`
- `MerchantAddCategoryFormController`

Providers remain the source of truth for form state (`isSubmitting`, `errorMessage`, field values used by submit flow).

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

**Key Point**: The entire app is wrapped in `ProviderScope`, enabling Riverpod functionality throughout the widget tree.

## Current State Management Pattern

### StateProvider for View Management

The app uses `StateProvider` to manage which authentication view is displayed.

#### Provider Definition

```dart
// presentation/provider/auth/auth_provider.dart

/// Enum defining all possible authentication views
enum AuthView {
  welcome,          // Initial welcome screen
  login,            // Login type selection
  register,         // Registration form
  riderLogin,       // Rider authentication
  merchantLogin     // Merchant authentication
}

/// Controls which view is shown on the AuthScreen
final authViewProvider = StateProvider<AuthView>(
  (ref) => AuthView.welcome
);
```

**Pattern Highlights:**
- **Enum-Based**: Type-safe view states
- **StateProvider**: Simplest provider type for mutable state
- **Default Value**: Starts with `AuthView.welcome`
- **Single Source of Truth**: One provider controls entire auth flow

### Consumer Pattern

The app uses `ConsumerWidget` to access and react to state changes:

```dart
class WelcomeContent extends ConsumerWidget {
  const WelcomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Login',
          onPressed: () {
            // Update state to show login view
            ref.read(authViewProvider.notifier).state = AuthView.login;
          },
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Register',
          onPressed: () {
            // Update state to show register view
            ref.read(authViewProvider.notifier).state = AuthView.register;
          },
        ),
      ],
    );
  }
}
```

**Key Methods:**
- `ref.read(provider.notifier).state = newValue` - Update state without listening
- `ref.watch(provider)` - Listen to state changes and rebuild on update
- `ref.listen(provider, callback)` - Perform side effects on state change

### Watching State in Screen

```dart
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for state changes - rebuilds when authView changes
    final authView = ref.watch(authViewProvider);
    final isWelcome = authView == AuthView.welcome;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Static components
            const AuthTopBar(),
            const AuthIllustration(),
            
            // Dynamic content based on state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (authView) {
                AuthView.welcome => const WelcomeContent(),
                AuthView.login => const LoginContent(),
                AuthView.register => const RegisterContent(),
                AuthView.riderLogin => const RiderLoginContent(),
                AuthView.merchantLogin => const MerchantLoginContent(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pattern Benefits:**
- Clean separation of concerns
- Type-safe state management
- Automatic UI updates
- Smooth transitions with AnimatedSwitcher

### State-Driven Animations

The app uses state to drive not just content but also animations:

```dart
class AuthIllustration extends ConsumerWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state to determine which illustration to show
    final authView = ref.watch(authViewProvider);
    final isRiderLogin = authView == AuthView.riderLogin || 
                         authView == AuthView.merchantLogin;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2F2F7),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child
              ),
            );
          },
          // State determines which SVG to display
          child: isRiderLogin
              ? SvgPicture.asset(
                  'assets/images/Lesgo.svg',
                  key: const ValueKey('lesgo_illustration'),
                )
              : SvgPicture.asset(
                  'assets/images/Logo.svg',
                  key: const ValueKey('logo_illustration'),
                ),
        ),
      ),
    );
  }
}
```

**Animation Features:**
- State-driven visual changes
- Smooth fade and scale transitions
- Unique keys for AnimatedSwitcher to detect changes

## Provider vs Controller — Key Difference

> [!IMPORTANT]
> This separation is a **core architectural pattern** shared across FRONTEND and RIDERSIDE.

### Quick Summary

| | **Provider** | **Controller** |
|---|---|---|
| **Purpose** | Manages shared state | Controls specific widget behavior |
| **Rebuilds UI** | ✅ Automatically via `ref.watch()` | ❌ Does not rebuild UI |
| **Contains** | State class + StateNotifier + provider definition | Plain class with TextEditingControllers, ImagePickers, etc. |
| **Named** | `*_provider.dart`, `*Notifier`, `*Provider` | `*_controller.dart`, `*Controllers` |
| **Base class** | `extends StateNotifier<State>` | Plain Dart class (no base class) |
| **Used for** | Global/shared app data, async operations | Form field management, UI-specific orchestration |

### Provider File (manages state)

Contains **State class + StateNotifier + provider definition** — all in one file.

```dart
// rider_register_info_provider.dart
class RegisterInfoState { ... }                      // State
class RegisterInfoNotifier extends StateNotifier<RegisterInfoState> { ... } // Logic
final registerInfoProvider = StateNotifierProvider<...>(...);               // Provider def
```

### Controller File (UI orchestration)

Contains a **plain class** with Flutter widget controllers and UI interaction methods that call into the provider.

```dart
// profile.controller.notifier.dart (FRONTEND example)
class ProfileControllers {
  final TextEditingController address1Controller;
  final TextEditingController address2Controller;

  Future<void> showImagePicker(BuildContext context, WidgetRef ref) async { ... }
  Future<void> updateAddresses(BuildContext context, WidgetRef ref) async {
    await ref.read(profileProvider.notifier).updateProfile(...);
    SnackBarUtils.showSuccess(context, 'Updated!');
  }
  void dispose() { ... }
}
```

### When to use which?

- **Need state that rebuilds UI? → Provider**
- **Need TextEditingControllers, image pickers, snackbar triggers? → Controller**
- **Simple enum/boolean toggle? → `StateProvider` in a provider file**

---

## Registration State Management (StateNotifier)

### Register Providers (Simple State)

```dart
// presentation/provider/register/register_provider.dart

/// Checkbox state for terms acceptance
final termsAcceptedProvider = StateProvider<bool>((ref) => false);

/// Tracks if user completed the terms step
final hasAcceptedTermsProvider = StateProvider<bool>((ref) => false);
```

### Phone Verification Provider

**File:** `presentation/provider/register/riderside/rider_phone_verification_provider.dart`

```dart
class PhoneVerificationState {
  final String phoneNumber;
  final bool otpSent;
  final bool isLoading;
  final String? errorMessage;
  final bool isVerified;

  bool get isPhoneNumberValid => phoneNumber.length == 10;
  // Has: copyWith with clearError pattern
}

class PhoneVerificationNotifier
    extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationNotifier() : super(const PhoneVerificationState());

  void updatePhoneNumber(String phoneNumber);
  Future<void> sendOTP();        // Validates phone, sends OTP
  Future<void> resendOTP();      // Resends OTP
  Future<bool> verifyOTP(String otp);  // Returns true on success
  void reset();
  void clearError();
}

final phoneVerificationProvider =
    StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>(
  (ref) => PhoneVerificationNotifier(),
);
```

### Registration Info Provider

**File:** `presentation/provider/register/riderside/rider_register_info_provider.dart`

```dart
class RegisterInfoState {
  final RiderRegistrationInfo registrationInfo;  // Domain entity
  final RiderDocuments documents;                 // Domain entity
  // ... individual loading states per upload ...
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSubmitted;
  final bool hasAttemptedSubmit;

  bool get isFormValid => registrationInfo.isValid && documents.isComplete;
}

class RegisterInfoNotifier extends StateNotifier<RegisterInfoState> {
  // Form field updates, camera/file uploads, submit flow
}

final registerInfoProvider =
    StateNotifierProvider<RegisterInfoNotifier, RegisterInfoState>(...);
```

### Merchant Registration Info Provider

**File:** `presentation/provider/register/merchant/merchant_register_info_provider.dart`

Similar to the Rider provider but tailored for the single-screen Merchant flow.

```dart
class MerchantRegisterInfoState { ... }
class MerchantRegisterInfoNotifier extends StateNotifier<MerchantRegisterInfoState> { ... }
final merchantRegisterInfoProvider = StateNotifierProvider.autoDispose<...>(...);
```

**Key Design Decisions:**
- State uses domain entities (`RiderRegistrationInfo`, `RiderDocuments`) not raw fields
- Each upload method has its own loading flag for individual progress indicators
- `attemptSubmit` receives `isFormFieldsValid` from `Form.validate()` in the UI
- `hasAttemptedSubmit` controls when upload widgets show red error borders
- `clearError` pattern uses a `bool clearError = false` parameter in copyWith

### Screen ↔ Controller Pattern

Screens are purely presentational — they compose widgets and wire state:

```dart
// Screen (presentation only)
class RegisterInfoScreen extends ConsumerStatefulWidget {
  // Owns: FormKey, TextEditingControllers
  // initState: attaches listeners that call controller.updateXxx()
  // dispose: disposes controllers
  // _handleSubmit: calls Form.validate() then controller.attemptSubmit()
  
  // build:
  //   ref.watch() — reads state
  //   ref.listen() — handles side effects (errors → snackbar, submitted → navigate)
  //   Returns RegisterScaffold with composed widgets
}
```

**Rules:**
1. Screens own `TextEditingController`s and `GlobalKey<FormState>`
2. Screens sync text changes to controller via `.addListener`
3. Screens call controller methods for actions (submit, upload)
4. Screens use `ref.listen` for side effects (snackbars, navigation)
5. All business logic lives in the controller — screens never decide outcomes

## Data Flow

### Auth Flow (Simple StateProvider)

```
User Action → Widget → StateProvider Update → State Change → UI Rebuild
```

### Registration Flow (StateNotifier)

```
User Action → Screen → Controller Method → State Update → UI Rebuild
                                              ↓
                                    ref.listen (side effects: snackbar, navigation)
```

**Example — Submit Registration:**
```dart
// 1. User taps Submit button
PrimaryButton(onPressed: _handleSubmit)

// 2. Screen calls Form.validate() + controller
void _handleSubmit() {
  final isFormFieldsValid = _formKey.currentState?.validate() ?? false;
  ref.read(registerInfoControllerProvider.notifier)
      .attemptSubmit(isFormFieldsValid: isFormFieldsValid);
}

// 3. Controller handles business logic
void attemptSubmit({required bool isFormFieldsValid}) {
  state = state.copyWith(hasAttemptedSubmit: true);
  if (isFormFieldsValid && state.documents.isComplete) {
    submitForm();
  } else {
    state = state.copyWith(errorMessage: 'Please fill in all fields...');
  }
}

// 4. Screen listens for side effects
ref.listen<RegisterInfoState>(registerInfoControllerProvider, (prev, next) {
  if (next.errorMessage != null) {
    SnackBarUtils.showError(context, next.errorMessage!);
    controller.clearError();
  }
  if (next.isSubmitted) {
    Navigator.push(context, RegisterCompleteScreen());
  }
});
```

## Local State Management

For form-specific state (like "Remember Me" checkbox), the app uses traditional StatefulWidget:

```dart
class RiderLoginContent extends StatefulWidget {
  const RiderLoginContent({super.key});

  @override
  State<RiderLoginContent> createState() => _RiderLoginContentState();
}

class _RiderLoginContentState extends State<RiderLoginContent> {
  // Local state - not shared across widgets
  bool isRememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(hintText: 'Email/Phone'),
        CustomTextField(hintText: 'Password', isPassword: true),
        
        // Local state for checkbox
        Checkbox(
          value: isRememberMe,
          onChanged: (value) {
            setState(() {
              isRememberMe = value ?? false;
            });
          },
        ),
        
        PrimaryButton(
          text: 'Log In',
          onPressed: () {
            // TODO: Use isRememberMe value in authentication
          },
        ),
      ],
    );
  }
}
```

**Decision Criteria:**
- **Use StateProvider/Riverpod** for: Shared state, navigation state, app-level state
- **Use StatefulWidget** for: Local form state, temporary UI state, widget-specific state

## Future State Management Patterns

As the app grows, the state management will evolve to handle more complex scenarios.

### Phase 1: Authentication StateNotifier

```dart
// Future implementation
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  AuthNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
  }) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await loginUseCase(
        LoginParams(email: email, password: password),
      );
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _mapFailureToMessage(failure),
          );
        },
        (user) {
          state = state.copyWith(
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await logoutUseCase();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
  );
});
```

### Phase 2: Order Management State

```dart
class OrderState {
  final List<Order> activeOrders;
  final List<Order> completedOrders;
  final Order? selectedOrder;
  final bool isLoading;
  final String? error;

  OrderState({
    this.activeOrders = const [],
    this.completedOrders = const [],
    this.selectedOrder,
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({...}) {
    return OrderState(...);
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final GetActiveOrdersUseCase getActiveOrdersUseCase;
  final AcceptOrderUseCase acceptOrderUseCase;
  final CompleteOrderUseCase completeOrderUseCase;

  OrderNotifier({
    required this.getActiveOrdersUseCase,
    required this.acceptOrderUseCase,
    required this.completeOrderUseCase,
  }) : super(OrderState());

  Future<void> fetchActiveOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await getActiveOrdersUseCase();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (orders) => state = state.copyWith(
        activeOrders: orders,
        isLoading: false,
      ),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    // Implementation
  }

  Future<void> completeOrder(String orderId) async {
    // Implementation
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(
    getActiveOrdersUseCase: ref.read(getActiveOrdersUseCaseProvider),
    acceptOrderUseCase: ref.read(acceptOrderUseCaseProvider),
    completeOrderUseCase: ref.read(completeOrderUseCaseProvider),
  );
});
```

### Phase 3: Real-Time State (Delivery Tracking)

```dart
class DeliveryState {
  final Order? currentOrder;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
  final List<LatLng> routePoints;
  final double distanceRemaining;
  final Duration estimatedTime;
  final DeliveryStatus status;

  DeliveryState({...});
}

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final StreamSubscription<Position>? _locationSubscription;
  final UpdateLocationUseCase updateLocationUseCase;

  DeliveryNotifier({
    required this.updateLocationUseCase,
  }) : super(DeliveryState.initial());

  void startTracking(Order order) {
    _locationSubscription = Geolocator.getPositionStream()
      .listen((position) {
        final location = LatLng(
          position.latitude,
          position.longitude,
        );
        
        state = state.copyWith(currentLocation: location);
        updateLocationUseCase(location);
      });
  }

  void stopTracking() {
    _locationSubscription?.cancel();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
```

## State Management Best Practices

### Current Implementation

#### ✅ Do's

```dart
// Use StateProvider for simple state
final authViewProvider = StateProvider<AuthView>(
  (ref) => AuthView.welcome
);

// Use ConsumerWidget for accessing providers
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    return Widget();
  }
}

// Update state without listening
ref.read(authViewProvider.notifier).state = AuthView.login;

// Watch for rebuilds
final authView = ref.watch(authViewProvider);
```

#### ❌ Don'ts

```dart
// Don't use watch in callbacks (use read instead)
onPressed: () {
  final view = ref.watch(authViewProvider); // ❌ Wrong
  final view = ref.read(authViewProvider);  // ✅ Correct
}

// Don't use Provider.of (use ref.watch/read)
Provider.of<AuthView>(context) // ❌ Wrong (Provider package)
ref.watch(authViewProvider)    // ✅ Correct (Riverpod)
```

### Future Best Practices

#### Immutable State

```dart
✅ Do:
state = state.copyWith(isLoading: true);

❌ Don't:
state.isLoading = true; // State is immutable!
```

#### Error Handling

```dart
// Always include error states
class SomeState {
  final bool isLoading;
  final String? error;
  final Data? data;
}

// Handle errors in UI
if (state.error != null) {
  return ErrorWidget(error: state.error!);
}
```

#### Loading States

```dart
// Show loading indicators
if (state.isLoading) {
  return CircularProgressIndicator();
}
```

## Provider Organization

### Current Structure

```
presentation/provider/
├── auth/
│   └── auth_provider.dart                              (StateProvider<AuthView>)
├── main/
│   ├── riderside/
│   │   ├── rider_main_nav_provider.dart                (StateNotifier<List<RiderNavType>>)
│   │   │                                               RiderNavNotifier: navigateTo(), pop(), current
│   │   ├── rider_history_provider.dart                 (State + Notifier + Provider)
│   │   └── rider_duty_provider.dart                    (StateProvider<bool>)
│   └── merchantside/
│       └── merchant_nav_provider.dart                  (StateProvider<MerchantNavType>)
└── register/
    ├── register_provider.dart                          (StateProvider<bool> x2)
    ├── riderside/
    │   ├── rider_register_info_provider.dart            (State + Notifier + Provider)
    │   └── rider_phone_verification_provider.dart       (State + Notifier + Provider)
    └── merchant/
        └── merchant_register_info_provider.dart         (State + Notifier + Provider)
```

### Rider Main Nav Provider (Stack-Based StateNotifier)

**File:** `presentation/provider/main/riderside/rider_main_nav_provider.dart`

```dart
enum RiderNavType { bookings, history, profile, wallet, mission }

class RiderNavNotifier extends StateNotifier<List<RiderNavType>> {
  RiderNavNotifier() : super(const [RiderNavType.bookings]);

  RiderNavType get current => state.last;

  void navigateTo(RiderNavType type) {
    if (state.last == type) return;
    if (type == RiderNavType.bookings) {
      state = const [RiderNavType.bookings]; return;   // Always resets to root
    }
    final filtered = state.where((t) => t != type).toList();
    state = [...filtered, type];                       // Dedup then push
  }

  bool pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1); return true;
    }
    return false;
  }
}

final riderNavProvider =
    StateNotifierProvider<RiderNavNotifier, List<RiderNavType>>(
  (ref) => RiderNavNotifier(),
);
```

**Key Behaviors:**
- `navigateTo(bookings)` → always resets stack to `[bookings]`
- `navigateTo(X)` → deduplicates X from current stack, then appends X
- `pop()` → removes last entry; returns `false` if already at root (allows app exit)
- `PopScope(canPop: navStack.length <= 1)` in `RiderMainScreen` gates system back button

### History Feature Provider

**File:** `presentation/provider/main/riderside/rider_history_provider.dart`

```dart
class RiderHistoryState {
  final String selectedFilter;
  final List<Map<String, String>> allBookings;
  final int totalBookings;
  final int performanceStars;

  static const List<String> filterOptions = ['All', 'Completed', 'Processing', 'Cancelled'];

  List<Map<String, String>> get filteredBookings { ... }  // Derived from selectedFilter
  Map<String, int> get statusCounts { ... }               // Counts per status
  List<double> get chartDataPoints { ... }                // Normalized 0.0–1.0 for fl_chart
  static Color statusColor(String status) { ... }         // Badge text color
  static Color statusBackgroundColor(String status) { ... } // Badge bg color
}

class RiderHistoryNotifier extends StateNotifier<RiderHistoryState> {
  void updateFilter(String filter);
}

final riderHistoryProvider =
    StateNotifierProvider<RiderHistoryNotifier, RiderHistoryState>(...);
```

## Testing State Management

### Current Testing

```dart
void main() {
  test('authViewProvider should start with welcome', () {
    final container = ProviderContainer();
    
    expect(
      container.read(authViewProvider),
      AuthView.welcome,
    );
  });

  test('authViewProvider should update state', () {
    final container = ProviderContainer();
    
    container.read(authViewProvider.notifier).state = AuthView.login;
    
    expect(
      container.read(authViewProvider),
      AuthView.login,
    );
  });
}
```

### Future Testing

```dart
void main() {
  late AuthNotifier authNotifier;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    authNotifier = AuthNotifier(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
    );
  });

  test('login should update state correctly', () async {
    when(mockLoginUseCase(any))
      .thenAnswer((_) async => Right(mockUser));
    
    await authNotifier.login('test@test.com', 'password');
    
    expect(authNotifier.state.user, mockUser);
    expect(authNotifier.state.isAuthenticated, true);
    expect(authNotifier.state.isLoading, false);
  });

  test('login failure should set error', () async {
    when(mockLoginUseCase(any))
      .thenAnswer((_) async => Left(ServerFailure()));
    
    await authNotifier.login('test@test.com', 'password');
    
    expect(authNotifier.state.error, isNotNull);
    expect(authNotifier.state.isAuthenticated, false);
  });
}
```

## Performance Considerations

### Selective Rebuilds

```dart
// Watch entire state (rebuilds on any change)
final authState = ref.watch(authProvider);

// Watch specific property (rebuilds only when user changes)
final user = ref.watch(authProvider.select((state) => state.user));

// Watch computed property
final isAuthenticated = ref.watch(
  authProvider.select((state) => state.isAuthenticated)
);
```

### Provider Scope

```dart
// Scoped providers for features
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(...),
);

// Auto-dispose when not in use
final orderProvider = StateNotifierProvider.autoDispose<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(...),
);
```

## Key Advantages of Current Approach

1. **Simplicity**: Easy to understand and implement
2. **Type Safety**: Enum-based state prevents invalid states
3. **Minimal Boilerplate**: No complex state classes needed yet
4. **Clear Intent**: State changes are explicit and traceable
5. **Smooth Animations**: State drives visual transitions
6. **Scalable**: Easy to evolve into more complex patterns

## Migration Path

### From StateProvider to StateNotifier

**Before (Current):**
```dart
final authViewProvider = StateProvider<AuthView>(
  (ref) => AuthView.welcome
);
```

**After (Future):**
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());
  
  // Methods to update state
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier()
);
```

## Comparison with FRONTEND

| Aspect | FRONTEND | RIDERSIDE |
|--------|----------|-----------|
| **Complexity** | High (StateNotifier + Mixins) | Medium (StateProvider + StateNotifier) |
| **State Classes** | Multiple with copyWith | Domain entities + State classes with copyWith |
| **Patterns** | StateNotifier, Mixins | StateProvider, StateNotifier |
| **Provider/Controller** | Same pattern — provider file contains State+Notifier+provider, controller has UI classes | Same pattern |
| **Maturity** | Production-ready | Auth + Registration + History complete |
| **Boilerplate** | Higher (but organized) | Moderate (growing with features) |

## Conclusion

The RIDERSIDE application uses a **pragmatic, progressive approach** to state management:

- **Simple state** (`StateProvider`) for basic view switching and boolean flags
- **Complex state** (`StateNotifier` + immutable State + domain entities) for registration flows with uploads, validation, and submission
- **Provider files** contain State + Notifier + provider definition (manages shared state, rebuilds UI)
- **Controller files** contain plain classes for UI orchestration (TextEditingControllers, image pickers) — does NOT rebuild UI
- **Widgets are purely presentational** — receive all data via constructor params, zero business logic
- **Screens are thin** — compose widgets and wire state via `ref.watch`, `ref.listen`, `ref.read`
- **Side effects** handled via `ref.listen` (snackbars, navigation) — never in providers

The architecture is ready to add the data layer (repositories, API calls) into the existing providers.
