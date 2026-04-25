# Architecture Documentation - Lezgo RIDERSIDE

## Overview

The RIDERSIDE application follows **Clean Architecture** principles with a structured 4-layer approach. This architecture provides clear separation of concerns and is designed to scale as the application grows, with a focus on maintainability, testability, and independence from frameworks.

## Latest Merchantside Architecture Update (Menu Forms)

The merchant menu form stack was refactored to a thinner screen architecture with reusable layout/widget primitives and provider-driven initialization.

- Added shared form layout shell with sticky bottom action support (`MerchantFormLayout` + `stickyBottomAction`).
- Added form controller layer for TextEditingController lifecycle management:
  - `MerchantMenuItemFormController`
  - `MerchantAddCategoryFormController`
- Updated form provider initialization to use typed input model (`MerchantMenuItemFormInput`) instead of ad hoc `Map` construction inside screens.
- Consolidated widget exports into the central `widgets.dart` barrel file and removed menu-local `index.dart` barrels.
- Merchant menu screens now follow a thin-screen pattern: compose sections, wire provider/controller callbacks, and keep business/state logic in notifier/provider.

### Merchantside Menu Screens (Current)

- `merchant_menu_add_item_screen.dart`
  - Sticky action buttons
  - Uses form controller + typed provider input (`MerchantMenuItemFormInput.add()`)
  - `Live on Menu` and dietary UI removed per latest UX updates
- `merchant_menu_edit_item_screen.dart`
  - Sticky action buttons
  - Uses form controller + typed provider input (`MerchantMenuItemFormInput.edit(...)`)
  - Dietary UI removed per latest UX updates
- `merchant_menu_add_category_screen.dart`
  - Sticky action buttons
  - Uses category form controller + non-family provider

## Architecture Pattern

### Clean Architecture - 4 Layers

```
lib/
├── presentation/     # UI Layer (Screens, Widgets, Providers)
├── domain/          # Business Logic Layer (Entities, Use Cases, Repository Interfaces)
├── data/            # Data Layer (Repository Implementations, Data Sources, Models)
└── core/            # Shared utilities, constants, and dependency injection
```

## Current Implementation Status

The RIDERSIDE app is structured for **scalability** with a complete Clean Architecture setup. The **registration flow** is fully implemented, and the **main app navigation** (with stack-based back handling, SVG nav icons, logout, and per-tab views) is implemented.

| Layer | Status | Contents |
|-------|--------|----------|
| **Presentation** | ✅ Implemented | Auth, Registration flows (Rider/Merchant), Main App Navigation (stack-based Bottom Tabs with PopScope), Bookings/History/Profile/Wallet/Mission views, Booking Detail screen (with category-specific status grid + banner SVG), Logout dialog, SVG nav icons. 55+ reusable widgets. |
| **Domain** | ✅ Partial | Entities implemented (RiderRegistrationInfo, RiderDocuments, RiderBooking + BookingCategory + BookingStatus with 11 values + extensions). Usecases/repositories prepared |
| **Data** | 🏗️ Prepared | Folder structure ready (datasources, models, repositories); `fakedata.dart` in core/utils/helpers for mock data |
| **Core** | ✅ Implemented | Utils, constants, validators (4 validator classes), helpers (fakedata.dart), DI setup |

## Layer Breakdown

### 1. Presentation Layer (`lib/presentation/`)

The presentation layer handles all UI-related concerns and user interactions.

#### Structure:
```
presentation/
├── provider/        # State management (Riverpod)
│   ├── auth/
│   │   └── auth_provider.dart
│   └── register/
│       ├── register_provider.dart
│       └── controller/
│           ├── rider/
│           │   ├── register_info_controller.dart
│           │   └── register_phone_verification_controller.dart
│           └── merchant/
│               └── merchant_register_info_controller.dart
├── screens/         # Full-page UI components
│   ├── auth/
│   │   └── auth_screen.dart
│   └── register/
│       ├── rider/
│       │   ├── register_screen.dart
│       │   ├── register_phone_verification_screen.dart
│       │   ├── register_info_screen.dart
│       │   └── register_complete_screen.dart
│       └── merchant/
│           ├── merchant_register_screen.dart
│           └── merchant_register_complete_screen.dart
└── widgets/         # Reusable UI components
    ├── auth/
    │   ├── auth_illustration.dart
    │   ├── auth_top_bar.dart
    │   ├── welcome_content.dart
    │   ├── login_content.dart
    │   ├── register_content.dart
    │   ├── rider_login_content.dart
    │   └── merchant_login_content.dart
    ├── global/
    │   ├── primary_button.dart
    │   ├── custom_text_field.dart
    │   ├── top_bar.dart
    │   ├── home_header.dart          # Added Widget? action optional slot
    │   ├── register_scaffold.dart
    │   └── confirm_dialog.dart       # showConfirmDialog() reusable confirmation dialog
    ├── register/
    │   ├── terms_and_conditions/
    │   │   ├── terms_header.dart
    │   │   ├── terms_scrollable_content.dart
    │   │   └── terms_acceptance_checkbox.dart
    │   ├── phone_verification/
    │   │   ├── phone_input_field.dart
    │   │   ├── otp_input_boxes.dart
    │   │   ├── verification_code_section.dart
    │   │   ├── phone_verification_illustration.dart
    │   │   ├── send_otp_button.dart
    │   │   ├── resend_otp_button.dart
    │   │   ├── section_label.dart
    │       ├── file_upload_box.dart
    │       ├── document_upload_section.dart
    │       ├── document_upload_list.dart
    │       ├── info_section_label.dart
    │       └── submit_info_text.dart
    └── widgets.dart  # Central exports (barrel file)
```

**Key Characteristics:**
- **Screen Architecture**: Auth uses single-screen view switching; Registration uses multi-screen navigation
- **State-Driven UI**: UI responds to state changes from StateNotifier controllers
- **Anti-Monolith Widget Composition**: Screens and Views **must be explicitly widget-based and not monoliths**. Large screens (e.g., Profile or Wallet views) must be broken down into smaller, focused composed widgets (e.g., `RiderWalletCard`, `RiderProfileInfoSection`) and assembled in the main view file.
- **Screens have NO business logic**: All logic lives in controllers; screens only call controller methods
- **Responsive Design**: All sizing uses `ResponsiveUtils` for device adaptation

### 2. Domain Layer (`lib/domain/`)

The domain layer contains pure business logic entities, independent of frameworks.

#### Structure:
```
domain/
├── entities/        # Business entities (pure Dart classes)
│   ├── rider_registration_info.dart
│   └── rider_documents.dart
├── repositories/    # Repository interfaces (contracts) - prepared
├── usecases/        # Business use cases - prepared
└── models/          # Domain-specific models - prepared
```

#### Implemented Entities:

**MerchantEntities** — Similar structure for Merchant:
- `MerchantRegistrationInfo`: restaurantName, ownerName, etc.
- `MerchantDocuments`: validId, permits, etc.

**RiderRegistrationInfo** — Personal registration data:
```dart
class RiderRegistrationInfo {
  final String firstName;
  final String lastName;
  final String birthday;
  final String email;

  bool get isValid => firstName.isNotEmpty && lastName.isNotEmpty && 
                      birthday.isNotEmpty && email.isNotEmpty;

  // Has: copyWith, toJson, fromJson, empty() factory
}
```

**RiderDocuments** — 8 document upload paths:
```dart
class RiderDocuments {
  final String? selfieImagePath;
  final String? selfieWithMotorcycleImagePath;
  final String? resumeFilePath;
  final String? barangayClearanceFilePath;
  final String? driversLicenseFilePath;
  final String? motorcycleORCRImagePath;
  final String? scannedORCRFilePath;
  final String? digitalSignatureFilePath;

  bool get isComplete => /* all 8 fields non-null */;

  // Has: copyWith, toJson, fromJson, empty() factory
}
```

**RiderBooking** — Booking entity with category, status, and billing:
```dart
enum BookingCategory { lesEat, lesBuy, lesRide }
extension BookingCategoryLabel on BookingCategory {
  String get label { ... }   // e.g. "LesEat"
}
extension BookingCategoryStatuses on BookingCategory {
  List<BookingStatus> get statuses { ... }  // ordered status list per category
}

enum BookingStatus {
  // LesEat + shared
  pending, cooking, forPickUp, forDelivery, delivered,
  // LesBuy specific
  toBuy,
  // LesRide
  onTheWay, onTheWayGoing, driverHasArrived, inProgress, complete
}
extension BookingStatusX on BookingStatus {
  String get label { ... }          // display name e.g. "For Pick Up"
  String? get uploadLabel { ... }   // non-null for statuses needing proof upload
}

class RiderBooking {
  final String id;
  final String restaurantName;
  final String address;
  final String logoPath;
  final BookingCategory category;
  final String billingAmount;     // e.g. 'PHP 340.00'
  final String billingMethod;     // e.g. 'Cash on Delivery'
  final BookingStatus currentStatus; // default: BookingStatus.pending
}
```

**Principles:**
- **Framework Independent**: Pure Dart, no Flutter dependencies
- **Immutable**: All fields are final, use copyWith for updates
- **Self-Validating**: `isValid` and `isComplete` getters for validation
- **Serializable**: toJson/fromJson for API communication

### 3. Data Layer (`lib/data/`)

The data layer will implement domain repository interfaces and handle data operations.

#### Planned Structure:
```
data/
├── datasources/     # Data source implementations
│   ├── local/       # Local storage (SharedPreferences, SQLite, etc.)
│   └── remote/      # API calls, network operations
├── models/          # Data models (JSON serialization)
│   └── [future: user_model, response models, etc.]
└── repositories/    # Repository implementations
    └── [future: auth_repository_impl, etc.]
```

**Responsibilities:**
- **Data Fetching**: API calls, database queries
- **Data Transformation**: Convert between models and entities
- **Caching**: Local data persistence
- **Error Handling**: Network and data errors

**Future Repository Implementation Example:**
```dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      await localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

### 4. Core Layer (`lib/core/`)

The core layer provides shared functionality across all layers.

#### Structure:
```
core/
├── constants/       # App-wide constants
│   └── [API endpoints, strings, etc.]
├── di/              # Dependency Injection setup
│   └── [future: service locator, providers]
└── utils/           # Utility functions
    ├── utils.dart               # Central utils export
    ├── responsive_utils.dart   # Responsive sizing
    ├── snackbar_utils.dart     # Error/success snackbars
    ├── helpers/                # Helper utilities
    └── validators/             # Input validation
        ├── validators.dart     # Central validator export
        ├── register_validator.dart   # firstName, lastName, birthday, email
        ├── login_validator.dart      # email, password, phone, etc.
        ├── otp_validator.dart        # phoneNumber, otpCode, etc.
        └── profile_validator.dart    # name, address, plateNumber, etc.
```

**Components:**

#### Validators
Separated into feature-specific classes with static methods:
```dart
class RegisterValidator {
  static String? firstName(String? value) { /* validation logic */ }
  static String? lastName(String? value) { /* validation logic */ }
  static String? birthday(String? value) { /* validation logic */ }
  static String? email(String? value) { /* validation logic */ }
}
```
- Used in CustomTextField's `validator` parameter
- Return null for valid, error message string for invalid
- Validators check: required, min/max length, format (regex)

#### SnackBar Utilities
```dart
class SnackBarUtils {
  static void showError(BuildContext context, String message);
  static void showSuccess(BuildContext context, String message);
}
```

**Components:**

#### Responsive Utilities
```dart
// core/utils/responsive_utils.dart
class ResponsiveUtils {
  // Screen dimensions
  static double screenWidth(BuildContext context)
  static double screenHeight(BuildContext context)
  
  // Device type detection
  static bool isMobile(BuildContext context)    // < 600px
  static bool isTablet(BuildContext context)    // 600-1024px
  static bool isDesktop(BuildContext context)   // >= 1024px
  
  // Responsive sizing
  static double fontSize(BuildContext context, double baseSize)
  static double spacing(BuildContext context, double baseSpacing)
  static double horizontalPadding(BuildContext context)
  static double buttonHeight(BuildContext context)
  static double imageHeight(BuildContext context, double baseHeight)
  
  // Card utilities
  static double cardImageSize(BuildContext context, double baseSize)
  static double cardPadding(BuildContext context)
  static int cardDescriptionMaxLines(BuildContext context)
}
```

## Application Architecture

### Entry Point

```dart
// main.dart
void main() {
  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  const LesgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lezgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5F2D82),
        ),
        useMaterial3: true,
        fontFamily: 'TT Fors',
      ),
      home: const AuthScreen(),
    );
  }
}
```

**Key Points:**
- `ProviderScope`: Enables Riverpod state management
- Material 3 design system
- Custom theme with brand colors
- Custom font family (TT Fors)

### State-Based View Switching

The app uses an innovative **single-screen architecture** with view state management:

```dart
// Enum defining all auth views
enum AuthView {
  welcome,
  login,
  register,
  riderLogin,
  merchantLogin
}

// Provider to manage current view
final authViewProvider = StateProvider<AuthView>(
  (ref) => AuthView.welcome
);
```

**Benefits:**
- Smooth transitions between views
- Shared layout components (top bar, illustration)
- Centralized animation logic
- No route management needed for auth flows

### Screen Structure Pattern

```dart
class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed elements
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

**Key Features:**
- **AnimatedSwitcher**: Smooth transitions between views
- **Switch Expression**: Modern Dart pattern matching (Dart 3+)
- **ConsumerWidget**: Direct access to Riverpod providers
- **Shared Layout**: Top bar and illustration remain constant

## Data Flow

### Current Implementation (Presentation Only)

```
User Action → Widget → StateProvider → State Update → UI Rebuild
```

**Example Flow:**
```dart
// 1. User taps "Login" button
PrimaryButton(
  text: 'Login',
  onPressed: () {
    // 2. Update state provider
    ref.read(authViewProvider.notifier).state = AuthView.login;
  },
)

// 3. AuthScreen watches provider and rebuilds
final authView = ref.watch(authViewProvider);

// 4. UI updates based on new state
AnimatedSwitcher(
  child: switch (authView) {
    AuthView.login => const LoginContent(),
    // ...
  },
)
```

### Future Implementation (Full Clean Architecture)

```
User Action → Widget → Provider (StateNotifier)
                          ↓
                      Use Case
                          ↓
                      Repository Interface
                          ↓
                      Repository Implementation
                          ↓
                      Data Source (API/Local)
                          ↓
                      Data Model → Entity
                          ↓
                      State Update
                          ↓
                      UI Rebuild
```

## Navigation Strategy

### Main App Navigation: Stack-Based Bottom Tab Navigation

The rider main screen uses a **stack-based navigation model** via `riderNavProvider` (`StateNotifier<List<RiderNavType>>`):

```dart
// Stack behavior
navigateTo(bookings) → always resets: [bookings]
navigateTo(profile)  → dedup + push:  [bookings, profile]
navigateTo(wallet)   → dedup + push:  [bookings, profile, wallet]
back                 → pop:           [bookings, profile]
back                 → pop:           [bookings]
back                 → exits app (canPop: true when length == 1)
```

`PopScope(canPop: navStack.length <= 1)` in `RiderMainScreen` intercepts the physical back button and delegates to `riderNavProvider.notifier.pop()`.

### Auth Flow: PopScope Pattern

The auth screen uses `PopScope` for intuitive back navigation within the single-screen view switching:

```dart
PopScope(
  canPop: isWelcome,  // Only allow system back on welcome screen
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop && !isWelcome) {
      if (authView == AuthView.riderLogin || 
          authView == AuthView.merchantLogin) {
        ref.read(authViewProvider.notifier).state = AuthView.login;
      } else {
        ref.read(authViewProvider.notifier).state = AuthView.welcome;
      }
    } else if (didPop && isWelcome) {
      SystemNavigator.pop();
    }
  },
  child: /* screen content */,
)
```

### Registration Flow: Multi-Screen Navigation

The registration flow uses standard Flutter `Navigator.push` with `MaterialPageRoute`:

```
AuthScreen (Register) → RegisterScreen (Terms) → PhoneVerificationScreen → RegisterInfoScreen → RegisterCompleteScreen
```

Each screen navigates forward on completion and back on the back button.
Controllers are reset when navigating back (e.g., `controller.reset()` before `Navigator.pop()`).

**Navigation Hierarchy:**
```
Welcome Screen (Exit app on back)
    ↓
Login/Register (Back to welcome)
    ↓
Rider Login / Merchant Login (Back to login selection)
    ↓ (Register path)
Terms & Conditions (Back to auth)
    ↓
Phone Verification (Back to terms, resets controller)
    ↓
Registration Info (Back to phone verification)
    ↓
Registration Complete
```

## Responsive Design Strategy

### Multi-Device Support

The app adapts to different screen sizes:

```dart
// Breakpoints
Mobile:  < 600px  (phones)
Tablet:  600-1024px (tablets)
Desktop: >= 1024px (web/desktop)

// Adaptive padding
Desktop: 64px
Tablet:  48px
Mobile:  32px

// Adaptive font sizes
< 360px: 85% of base
< 400px: 95% of base
> 600px: 110% of base
Default: 100% of base
```

## Key Architectural Benefits

### 1. Scalability
- **Prepared Structure**: Domain and data layers ready for implementation
- **Clean Separation**: Easy to add new features without affecting existing code
- **Independent Layers**: Each layer can evolve independently

### 2. Testability
- **Pure Domain Logic**: Business logic will be framework-independent
- **Mockable Interfaces**: Repository contracts enable easy testing
- **Isolated UI**: Widgets can be tested with mock providers

### 3. Maintainability
- **Clear Structure**: Developers know exactly where code belongs
- **Single Responsibility**: Each class has one clear purpose
- **Consistent Patterns**: Same patterns used throughout the app

### 4. Flexibility
- **Swappable Data Sources**: Easy to switch between API, local storage, or mock data
- **UI Independence**: Can change UI without affecting business logic
- **Framework Agnostic Domain**: Business logic doesn't depend on Flutter

## Design Principles Applied

### 1. Dependency Inversion Principle (DIP)
- Presentation layer depends on domain interfaces
- Data layer implements domain interfaces
- Core provides dependency injection setup

### 2. Single Responsibility Principle (SRP)
- Each widget has one clear purpose
- Use cases handle single business operations
- Repositories manage specific data sources

### 3. Open/Closed Principle (OCP)
- Easy to extend with new features
- Existing code rarely needs modification
- New views added without changing core logic

### 4. Interface Segregation Principle (ISP)
- Small, focused repository interfaces
- Widgets consume only needed state
- Minimal dependencies between layers

## Application Type

**RIDERSIDE** serves two user types:
1. **Riders**: Delivery personnel who fulfill orders
2. **Merchants**: Business owners who receive and manage orders

The authentication flow separates these two user types with dedicated login screens (RiderLogin and MerchantLogin), allowing for role-based access and features.

## Technology Stack

- **Framework**: Flutter 3.10+
- **Language**: Dart 3+
- **State Management**: Riverpod (flutter_riverpod ^2.5.1)
- **Architecture**: Clean Architecture (4 layers)
- **Design System**: Material 3
- **Vector Graphics**: flutter_svg ^2.0.10+1
- **Camera**: image_picker ^1.0.7
- **File Selection**: file_picker ^8.0.0+1

## Future Roadmap

### Phase 1: Complete Domain Layer
- [x] Define core entities (RiderRegistrationInfo, RiderDocuments)
- [ ] Define remaining entities (User, Rider, Merchant, Order, etc.)
- [ ] Create repository interfaces
- [ ] Implement use cases for auth, orders, delivery

### Phase 2: Implement Data Layer
- [ ] Set up API client (Dio, http)
- [ ] Create remote data sources
- [ ] Implement local storage (SharedPreferences, Hive)
- [ ] Build repository implementations
- [ ] Add response models and serialization
- [ ] Connect registration flow to real API (replace TODO stubs)

### Phase 3: Dependency Injection
- [ ] Set up service locator (get_it) or use Riverpod's provider pattern
- [ ] Configure dependency injection container
- [ ] Register all dependencies

### Phase 4: Feature Expansion
- [ ] Order management screens
- [ ] Real-time delivery tracking
- [ ] Earnings/payments dashboard
- [ ] Notifications system
- [ ] Profile management

## Best Practices

### Current Implementation
1. ✅ Use `const` constructors for performance
2. ✅ Responsive design with `ResponsiveUtils`
3. ✅ Widget composition over complex widgets
4. ✅ State-driven UI updates
5. ✅ Proper use of `ConsumerWidget`

### When Implementing Domain/Data Layers
1. Keep domain entities pure (no Flutter dependencies)
2. Use `Either` type for error handling (dartz package)
3. Implement repository pattern correctly
4. Use dependency injection for all dependencies
5. Write unit tests for use cases
6. Mock repositories for widget tests

## Comparison with FRONTEND

| Aspect | FRONTEND | RIDERSIDE |
|--------|----------|-----------|
| **Architecture** | 3 layers (simplified) | 4 layers (full Clean Architecture) |
| **Navigation** | Named routes + router | View state switching + Navigator.push |
| **Complexity** | High (many features) | Medium (auth + full registration flow) |
| **Structure** | Feature-based | Layer-based |
| **Maturity** | Production-ready | Auth + Registration complete |
| **Use Case** | Customer app | Rider/Merchant app |

## Conclusion

The RIDERSIDE application demonstrates a **well-architected Flutter application** following Clean Architecture principles. The authentication and complete registration flows are implemented with:

- **Domain entities** for registration data (RiderRegistrationInfo, RiderDocuments)
- **StateNotifier controllers** managing all business logic (form state, uploads, validation, submission)
- **Thin screens** that only compose widgets and wire state — no business logic in screens
- **30+ reusable widgets** organized by feature (auth, terms, phone verification, registration info)
- **Validators** separated by feature (register, login, OTP, profile)
- **Shared layout widgets** (RegisterScaffold, TopBar) for consistent screen structure

The architecture is ready for the data layer (API integration) to connect the registration flow to a real backend. The clear separation of concerns and prepared layer structure make it easy to add new features as the application grows.
