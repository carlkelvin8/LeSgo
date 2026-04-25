# RIDERSIDE Implementation Memory

> This document tracks what has been implemented, key decisions made, and what remains for future sessions.

---

## Last Updated Session Summary

### What Was Implemented (All Sessions Combined)

#### 33. Food Detail & Cart Screens (Latest Session)
- Created `FoodDetailScreen` - dedicated full screen for viewing/adding food items
  - Displays food image, name, price, description
  - Size selection (9" or 12")
  - Variations with checkboxes (Pepperoni, Double Cheese, etc.)
  - Quantity selector with +/- buttons
  - Real-time subtotal calculation
  - "ADD ORDER" button wired to cart provider
  - Matches app design (purple gradient, TT Fors font, responsive)
- Created `CartScreen` - full cart management screen
  - Empty state with friendly message
  - List of cart items with size info and remove option
  - Price summary: subtotal + 12% tax + total
  - "PROCEED TO CHECKOUT" button (placeholder)
  - Item deletion via snackbar confirmation
  - Matches app design and patterns
- Updated `MerchantFoodGridItem` widget
  - Added optional `onTap` callback
  - Wrapped column in `GestureDetector` for tap detection
- Updated `merchant_book_view.dart`
  - Added navigation to FoodDetailScreen on food item tap
  - Passes food name, image, price, description
- Updated `MerchantMainScreen`
  - Cart icon now navigates to CartScreen (instead of snackbar)
  - Imported CartScreen in header
- Created `cart_provider.dart` with `CartState` and `CartNotifier` using `StateNotifierProvider`
  - Tracks `itemCount` and `items` (list of item IDs)
  - Methods: `addItem()`, `removeItem()`, `clearCart()`, `count` getter
- Created `cart_icon.dart` - `CartIcon` ConsumerWidget
  - Displays shopping cart icon from Material Icons
  - Shows red badge counter in top-right (e.g., "99+" if over 99 items)
  - Receives optional `onTap` callback for cart screen navigation
- Added `CartIcon` export to `widgets/widgets.dart` barrel
- Integrated `CartIcon` into `RiderMainScreen` header
  - Shows on all tabs except Profile (where logout icon appears)
  - Tap shows placeholder snackbar (ready for cart screen navigation)
  - Cart state is observed via `cartProvider` for reactive badge updates
- Introduced form controllers for menu forms:
  - `MerchantMenuItemFormController`
  - `MerchantAddCategoryFormController`
- Added reusable form shell:
  - `MerchantFormLayout` with `stickyBottomAction` slot for fixed bottom action bar
- Added reusable spacing helper `SectionSpacer`
- Added edit hero widget `MerchantItemHeroSection`
- Converted Add/Edit/Category form screens to thin composition using shared widgets + sticky action buttons

#### 24. Provider Initialization Cleanup (Latest Session)
- `merchant_menu_item_form_provider.dart` now uses typed provider key/input:
  - `MerchantMenuItemFormInput`
  - `MerchantMenuItemFormInput.add()` and `.edit(...)`
- Removed inline ad hoc initialization maps from Add/Edit screens
- `merchant_add_category_form_provider.dart` simplified from `StateNotifierProvider.family(..., String?)` to plain `StateNotifierProvider`

#### 25. Widget Export Consolidation (Latest Session)
- Removed merchantside menu local barrel files:
  - `menu/shared/index.dart`
  - `menu/add_menu/index.dart`
  - `menu/edit_menu/index.dart`
  - `menu/add_category/index.dart`
- Centralized exports in `widgets/widgets.dart` for all merchant menu widgets

#### 26. UX Adjustments Applied (Latest Session)
- Add Menu screen:
  - removed `Live on Menu` section
  - removed `Dietary Preferences` section
- Edit Menu screen:
  - removed `Dietary Preferences` section
- Edit Information screen was previously rolled back, then re-implemented as a dedicated screen with modular widgets and a bottom action bar

#### 27. Crash Fixes (Latest Session)
- Fixed `DropdownButton` assertion crash by hardening category dropdown selected-value handling
- Changed invalid default category (`Main Course`) to a valid category (`Pizza`) in menu item form provider defaults

#### 28. Edit Information Screen Re-Implemented (Latest Session)
- Added dedicated screen: `merchant_edit_information_screen.dart`
- Added dedicated controller: `MerchantEditInformationController` for text-controller lifecycle and save flow
- Added modular edit-information widgets:
  - `merchant_edit_information_header_section.dart`
  - `merchant_edit_information_field.dart`
  - `merchant_referral_code_field.dart`
  - `merchant_edit_information_action_bar.dart`
- Added save flow: validates required fields, updates `merchantProfileInfoData`, shows snackbar, then pops on success

#### 29. Global Two-Button Action Widget (Latest Session)
- Added reusable global widget: `global/dual_action_buttons.dart`
- Uses `PrimaryButton` for the primary action, preserving the app gradient pattern
- Enforced equal height between secondary and primary actions to remove mismatch
- Applied to:
  - Add Menu
  - Edit Menu
  - Add Category
  - Edit Information (profile)

#### 30. Merchantside Price Formatting Alignment (Latest Session)
- Removed `PHP` from mock `price` fields in `merchantFoodMenuItems` and related `price` mock entries in `fakedata.dart`
- Removed temporary price sanitize/normalize helpers from:
  - `merchant_menu_item_form_provider.dart`
  - `merchant_menu_item_form_controller.dart`
- Restored explicit `PHP` display only where needed in card UI:
  - `merchant_menu_item_card.dart` now renders `PHP $price`

#### 31. Merchantside Button Label Casing (Latest Session)
- Updated menu action labels from all-caps to title case:
  - `Add Item`
  - `Save Item`
  - `Create Category`

#### 9. Main Navigation — Stack-Based Back Handling (Latest Session)
- **`riderNavProvider`** upgraded from `StateProvider<RiderNavType>` to `StateNotifier<List<RiderNavType>>` with full push/pop stack behavior
- **Stack deduplication**: `navigateTo()` filters any existing occurrence of a tab before pushing, preventing duplicates
- **Bookings resets stack**: Tapping Bookings always resets the stack to `[bookings]` so back button exits the app from Bookings
- **`PopScope`** added to `RiderMainScreen` with `canPop: navStack.length <= 1`; `onPopInvokedWithResult` calls `ref.read(riderNavProvider.notifier).pop()` when stack has more than 1 entry
- Provider file: `lib/presentation/provider/main/riderside/rider_main_nav_provider.dart`

#### 10. Swipe Accept Button Fixes (Latest Session)
- **"Accepted" overlay**: When swipe completes (`_isAccepted = true`), centered "Accepted" text replaces the swipe hint; thumb stays at end
- **Threshold math fix**: Was `maxWidth * 0.75` (physically unreachable by thumb). Fixed to `(maxWidth - thumbWidth) * 0.75`
- File: `lib/presentation/widgets/main/riderside/bookings/rider_swipe_accept_button.dart`

#### 11. BookingCategory Enum (Latest Session)
- Added `BookingCategory` enum (`lesEat`, `lesBuy`, `lesRide`) with `.label` extension to `lib/domain/entities/rider_booking.dart`
- `RiderBooking` entity now has a `category` field
- Badge display was added then removed; enum retained in entity for future use

#### 12. Fake Data Centralization (Earlier Session)
- Created `lib/core/utils/helpers/fakedata.dart` as single source of all mock data
- Contains: `riderMockBookings` (List<RiderBooking>, 4 items with BookingCategory) and `riderMissions` (List<Map<String,dynamic>>, 5 items)
- `RiderBookingsList` and `RiderMissionView` now import from `fakedata.dart` instead of defining inline lists

#### 20. BookingStatus Enum + Entity Extension (Latest Session)
- Added `BookingStatus` enum (11 values) to `lib/domain/entities/rider_booking.dart`:
  - LesEat: `pending`, `cooking`, `forPickUp`, `forDelivery`, `delivered`
  - LesBuy-specific: `toBuy`
  - LesRide: `onTheWay`, `onTheWayGoing`, `driverHasArrived`, `inProgress`, `complete`
- Added `extension BookingStatusX on BookingStatus` → `.label` (display string), `.uploadLabel` (nullable — set for statuses needing upload proof)
- Added `extension BookingCategoryStatuses on BookingCategory` → `.statuses` returns the ordered `List<BookingStatus>` for each category
- `RiderBooking` entity updated with 3 new fields: `billingAmount` (e.g. `'PHP 340.00'`), `billingMethod` (e.g. `'Cash on Delivery'`), `currentStatus` (`BookingStatus`, defaults to `pending`)
- `fakedata.dart` mock bookings updated with billing data and `currentStatus` per entry

#### 21. Booking Detail Screen + Widgets (Latest Session)
- **4 new widgets** (all exported via `widgets.dart`):
  1. `rider_booking_status_button.dart` — gradient display tile; no tap, no border; text always `#2D2D2D`; each `BookingStatus` has a unique `LinearGradient`
  2. `rider_booking_status_grid.dart` — 2-column grid of status buttons; iterates `booking.category.statuses`; last button is full-width if odd count; display-only
  3. `rider_booking_detail_info.dart` — logo (110×110 container) + `_InfoRow` for Booking info (address) and Billing (amount + method)
  4. `rider_booking_status_button.dart` + `rider_booking_status_grid.dart` + `rider_booking_detail_info.dart` → exported in `widgets.dart`
- **New screen**: `lib/presentation/screens/main/riderside/rider_booking_detail_screen.dart`
  - `ConsumerStatefulWidget` with `RiderBooking booking` parameter
  - `_currentStatus` initialized from `booking.currentStatus` (local display state)
  - Layout: `SafeArea → Column`: `HomeHeader(showBackButton: true)` → banner `SizedBox` → `Expanded(SingleChildScrollView)` → `RiderBookingDetailInfo` + `Divider` + `'Status:'` label + `RiderBookingStatusGrid`
- **Navigation wired**: `RiderBookingCard` gained optional `VoidCallback? onTap`; `RiderBookingsList` gained `ValueChanged<RiderBooking>? onBookingTap`; `RiderBookingsView` calls `Navigator.push` to `RiderBookingDetailScreen` on tap

#### 22. Banner SVG — Booking Screens (Latest Session)
- Both `rider_bookings_header.dart` (main bookings tab) and `rider_booking_detail_screen.dart` (detail screen) now render the banner via:
  ```dart
  SvgPicture.asset('assets/images/booking/banner.svg', fit: BoxFit.cover)
  ```
- Replaced the old `Image.asset('assets/images/city_skyline_rider.png')` + error fallback grey container
- Asset file: `assets/images/booking/banner.svg` (registered in `pubspec.yaml` under `assets/images/booking/`)

#### 13. SVG Nav Icons — Riderside (Latest Session)
- Replaced all `Icon()` widgets in `RiderBottomNavBar` with `SvgPicture.asset()` with `ColorFilter.mode(color, BlendMode.srcIn)` for active/inactive tinting
- SVG mapping: `booking.svg`→Bookings, `time.svg`→History, `profile.svg`→Profile, `wallet.svg`→Wallet, `star.svg`→Mission
- Assets registered in `pubspec.yaml` under `assets/images/navbar/riderside/`

#### 14. SVG Nav Icons — Merchantside (Latest Session)
- Same SVG replacement for `MerchantBottomNavBar`
- Added `allowDrawingOutsideViewBox: true` to all icons to fix clipped spoon icon in `booking.svg` (SVG has tight internal `clipPath`)
- Assets registered in `pubspec.yaml` under `assets/images/navbar/merchant/`

#### 15. HomeHeader Action Slot (Latest Session)
- Added optional `Widget? action` parameter to `HomeHeader`
- Rendered as `Align(alignment: Alignment.centerRight)` inside the existing `Stack`
- Callers can pass any widget; if `null`, nothing renders

#### 16. Logout Button on Profile Tab (Latest Session)
- `RiderMainScreen` passes a red `Icons.exit_to_app_rounded` `GestureDetector` as the `action` to `HomeHeader` when `currentNav == RiderNavType.profile`
- Same pattern applied to `MerchantMainScreen` when `currentNav == MerchantNavType.profile`
- Tapping the icon calls `_showLogoutDialog(context, ref)`

#### 17. Reusable Confirm Dialog Widget (Latest Session)
- Created `lib/presentation/widgets/global/confirm_dialog.dart`
- Function: `showConfirmDialog({context, title, message, confirmLabel, cancelLabel, confirmColor, onConfirm})`
- Exported via `widgets.dart` barrel — available app-wide
- Usage: Pass `onConfirm` callback; Cancel dismisses, Confirm runs callback then dismisses

#### 18. Logout Navigation Flow (Latest Session)
- On logout confirm: resets `authViewProvider` to `AuthView.welcome` (prevents landing on a previous login sub-view), then `Navigator.pushAndRemoveUntil` to `AuthScreen` clearing the entire navigation stack
- Implemented identically in both `RiderMainScreen` and `MerchantMainScreen`

#### 19. Wallet Overflow Fix (Latest Session)
- Wrapped `RiderWalletView` Column in `SingleChildScrollView` to fix "BOTTOM OVERFLOWED BY 23 PIXELS" error

#### 1. Authentication Flow (Earlier Sessions)
- **Auth screen** with login/register view switching (state-driven via `authViewProvider`)
- **Smooth animations** between login and register views
- **Global / Reusable Widgets:**
    *   `PrimaryButton`: Standardized button with loading state.
    *   `CustomTextField`: Standardized text input with validation and password toggle.
    *   `AuthTopBar`, `AuthIllustration`: Resusable auth components.
    *   `RegisterScaffold`: Common scaffold for registration screens.
    *   `HomeHeader`: Generic top bar customizable via simple color bindings, now refactored to support varied backgrounds like the Mission Screen's transparent look.

#### 2. Registration Multi-Screen Flow (Core Sessions)
Three-screen registration flow navigated via `Navigator.push`:

**Screen 1: Terms & Conditions** (`register_screen.dart`)
- Composed of 3 widgets: `TermsHeader`, `TermsScrollableContent`, `TermsAcceptanceCheckbox`
- Logic lives in RegisterScreen (reads/toggles `termsAcceptedProvider`, `hasAcceptedTermsProvider`)
- Does NOT use RegisterScaffold (needs `Expanded` for scrollable content area)

**Screen 2: Phone Verification** (`register_phone_verification_screen.dart`)
- Uses `RegisterScaffold` + `PhoneVerificationForm` (composite widget)
- Controller: `RegisterPhoneVerificationController` (StateNotifier)
- Flow: Enter phone → Send OTP → Enter OTP → Verify → Navigate to info screen
- State: `PhoneVerificationState` tracks phone, otp, otpSent, isLoading, error

**Screen 3: Registration Info** (`register_info_screen.dart`)
- Uses `RegisterScaffold` + `DocumentUploadList` (composite widget)
- Controller: `RegisterInfoController` (StateNotifier, ~380 lines)
- Form: 4 text fields (firstName, lastName, birthday, email) with `Form` + `GlobalKey`
- Uploads: 2 selfie uploads + 6 document uploads (via image_picker / file_picker)
- Validation: `hasAttemptedSubmit` flag → red borders on invalid fields & empty uploads
- State: `RegisterInfoState` uses domain entities (`RiderRegistrationInfo`, `RiderDocuments`)

#### 3. Domain Entities
- **`RiderRegistrationInfo`**: firstName, lastName, birthday, email, `isValid` getter, copyWith, toJson/fromJson, `empty()` factory
- **`RiderDocuments`**: 8 nullable file path fields (front/backSelfie, driversLicense front/back, orCr front/back, plateNumber front/back), `isComplete` getter, copyWith, toJson/fromJson, `empty()` factory

#### 4. Validators (Core Layer)
4 files in `lib/core/utils/validators/`:
- `register_validator.dart` — validateName, validateBirthday, validateEmail (static methods)
- `login_validator.dart` — validatePhone, validatePassword
- `otp_validator.dart` — validateOtp
- `profile_validator.dart` — (prepared for future)

#### 5. Widget Architecture
30+ widgets organized in feature-based folders:
```
widgets/
├── global/          → TopBar, PrimaryButton, RegisterScaffold, CustomTextField
├── auth/            → AuthIllustration, LoginForm, RegisterForm, etc.
├── register/
│   ├── terms_and_conditions/  → TermsHeader, TermsScrollableContent, TermsAcceptanceCheckbox
│   ├── phone_verification/    → PhoneVerificationForm, PhoneInputField, OTPInputBoxes, etc.
│   └── info/                  → DocumentUploadList, InfoFormFields, SelfieUploadSection, etc.
└── profile/ & wallet/ → Refactored out monolithic views into composable parts (e.g., `RiderProfileHeader`, `RiderWalletCard`)
```

#### 6. Merchant Registration Flow
- **Single-Screen Process**: `MerchantRegisterScreen` combines info and uploads.
- **Controller**: `MerchantRegisterInfoController` handles validation and state.
- **Widgets**: `MerchantInfoFormFields`, `MerchantDocumentUploadList`.
- **Completion**: `MerchantRegisterCompleteScreen` with modular widgets.

#### 7. Widget Centralization & Modularization
- **Central Exports**: All widgets exported via `widgets.dart`.
- **Modular Complete Screens**: Rider and Merchant complete screens broken down into:
    - `HeaderSection` / `MerchantCompleteHeader`
    - `IllustrationSection` / `MerchantCompleteIllustration`
    - `InfoCardSection` / `MerchantCompleteInfoCard`
    - `ActionButtonsSection` / `MerchantCompleteActionButtons`

#### 8. Utility Layer
- `ResponsiveUtils` — scale factors for all sizing
- `SnackBarUtils` — error/success snackbars
- Central barrel exports: `widgets.dart` (40+ exports), `utils.dart` (7 exports), `validators.dart` (4 exports)

---

## Key Patterns & Decisions

### Screen ↔ Controller Pattern
- **Screens**: Own `_formKey`, `TextEditingControllers`, compose widgets, wire callbacks to controller
- **Controllers** (StateNotifier): Own ALL business logic — updates, validation checks, upload handling, submission
- **Rule**: No `if/else`, no validation logic, no data transforms in screens

### Validation Pattern
- **Text fields**: `Form.validate()` + `autovalidateMode.onUserInteraction` + red border only (no error text)
- **Upload widgets**: `showError` parameter + `hasAttemptedSubmit` from state → red border when empty
- **CustomTextField**: Uses `Future.microtask()` in validator to safely update `_errorMessage` state

### Widget Composition Layers (Anti-Monolith Strategy)
To ensure maintainability, **monolithic views are strictly prohibited**. Views must be broken down:
1. **Primitives**: Single-purpose (TopBar, PrimaryButton, CustomTextField)
2. **Sections**: Group related UI (InfoFormFields, SelfieUploadSection, RiderWalletActionsSection)
3. **Composites**: Combine multiple sections (DocumentUploadList, PhoneVerificationForm)
4. **Screens & Views**: Compose composites + wire state (thin, no logic). E.g., `RiderProfileView` and `RiderWalletView` only act as scaffolds importing modular pieces.

### State Management
- **Simple state**: `StateProvider` (authViewProvider, termsAcceptedProvider)
- **Complex state**: `StateNotifier` + freezed-like state classes (RegisterInfoController, PhoneVerificationController)
- **Listen pattern**: Screens use `ref.listen` to react to state changes (errors → snackbar, success → navigate)

---

## What's NOT Yet Implemented (TODO)

### Data Layer
- [ ] Repository interfaces (domain layer)
- [ ] Repository implementations (data layer)
- [ ] API service / HTTP client
- [ ] Local storage / caching

### Backend Integration
- [ ] Actual OTP sending (currently simulated)
- [ ] Actual form submission to backend
- [ ] File upload to server
- [ ] Authentication token management
- [ ] Wire logout to backend (clear tokens, invalidate session) — currently only resets local state

### Additional Features
- [ ] Login flow (controller + backend)
- [ ] Profile screen data (currently static fake data)
- [ ] Map integration (google_maps_flutter already in pubspec)
- [ ] Camera live capture (camera package already in pubspec)
- [ ] Booking acceptance backend call (swipe accept currently shows "Accepted" only, no API call)
- [ ] BookingCategory badge display (enum exists on entity, badge display was removed pending design decision)

### Infrastructure
- [ ] Error handling strategy (network errors, server errors)
- [ ] Loading states during API calls
- [ ] Retry logic
- [ ] Environment configuration (dev/staging/prod)

---

## File Reference (Current State)

### Presentation Layer
```
lib/presentation/
├── provider/
│   ├── auth/
│   │   └── auth_provider.dart              → authViewProvider (StateProvider<AuthView>)
│   ├── main/
│   │   ├── riderside/
│   │   │   ├── rider_main_nav_provider.dart → riderNavProvider (StateNotifier<List<RiderNavType>>)
│   │   │   │                                  RiderNavNotifier: navigateTo(), pop(), current getter
│   │   │   ├── rider_history_provider.dart  → RiderHistoryState + Notifier + Provider
│   │   │   └── rider_duty_provider.dart     → dutyProvider (StateProvider<bool>)
│   │   └── merchantside/
│   │       └── merchant_nav_provider.dart   → merchantNavProvider (StateProvider<MerchantNavType>)
│   └── register/
│       ├── register_provider.dart           → termsAcceptedProvider, hasAcceptedTermsProvider
│       ├── riderside/
│       │   ├── rider_register_info_provider.dart
│       │   └── rider_phone_verification_provider.dart
│       └── merchant/
│           └── merchant_register_info_provider.dart
├── screens/
│   ├── auth/
│   │   └── auth_screen.dart                → AuthView.welcome landing screen (Login/Register selection)
│   └── main/
│       ├── riderside/
│       │   ├── rider_main_screen.dart       → PopScope + HomeHeader(action: logout) + _showLogoutDialog
│       │   ├── rider_booking_detail_screen.dart → ConsumerStatefulWidget; HomeHeader(showBackButton) + banner SVG + detail info + status grid
│       │   └── views/
│       │       ├── rider_bookings_view.dart  → onBookingTap → Navigator.push to RiderBookingDetailScreen
│       │       ├── rider_profile_view.dart
│       │       ├── rider_wallet_view.dart   → SingleChildScrollView wrapper (overflow fix)
│       │       ├── rider_history_view.dart
│       │       └── rider_mission_view.dart  → maps over riderMissions from fakedata.dart
│       └── merchantside/
│           ├── merchant_main_screen.dart    → HomeHeader(action: logout) + _showLogoutDialog
│           ├── merchant_edit_information_screen.dart → dedicated edit profile information screen
│           ├── merchant_menu_add_item_screen.dart
│           ├── merchant_menu_edit_item_screen.dart
│           └── merchant_menu_add_category_screen.dart
└── widgets/
    ├── widgets.dart                         → Barrel export (50+ exports)
    ├── global/
    │   ├── primary_button.dart
    │   ├── dual_action_buttons.dart
    │   ├── custom_text_field.dart
    │   ├── top_bar.dart
    │   ├── home_header.dart                 → Added optional Widget? action parameter
    │   ├── register_scaffold.dart
    │   └── confirm_dialog.dart              → showConfirmDialog() reusable confirmation dialog
    ├── auth/                                → 7 widgets
    ├── main/
    │   ├── riderside/
    │   │   ├── rider_bottom_nav_bar.dart    → SvgPicture.asset icons (5 SVGs from navbar/riderside/)
    │   │   ├── bookings/
    │   │   │   ├── rider_swipe_accept_button.dart     → "Accepted" overlay + fixed threshold
    │   │   │   ├── rider_bookings_header.dart         → SvgPicture.asset banner.svg (replaced placeholder)
    │   │   │   ├── rider_booking_card.dart            → optional onTap wired for detail navigation
    │   │   │   ├── rider_bookings_list.dart           → onBookingTap callback → Navigator.push
    │   │   │   ├── rider_booking_status_button.dart   → gradient display tile, no tap, black text
    │   │   │   ├── rider_booking_status_grid.dart     → 2-col grid, display-only
    │   │   │   └── rider_booking_detail_info.dart     → logo + booking info + billing rows
    │   │   ├── history/                     → 4 widgets
    │   │   ├── profile/                     → 3 widgets
    │   │   ├── wallet/                      → 3 widgets
    │   │   └── mission/
    │   │       └── rider_mission_card.dart
    │   └── merchantside/
    │       ├── merchant_bottom_nav_bar.dart → SvgPicture.asset icons + allowDrawingOutsideViewBox
    │       ├── merchant_home_header.dart
    │       ├── orders/                      → merchant_order_card.dart, merchant_order_status_panel.dart, merchant_order_filter_chip.dart
    │       ├── menu/shared/                 → merchant_form_layout.dart, merchant_form_action_buttons_section.dart
    │       └── profile/edit_information/    → header/field/referral/action-bar widgets
    └── register/                            → 30+ widgets
```

### Domain Layer
```
lib/domain/entities/
├── rider_registration_info.dart
├── rider_documents.dart
└── rider_booking.dart                       → RiderBooking + BookingCategory enum (lesEat/lesBuy/lesRide)
                                                 + BookingStatus enum (11 values) + BookingStatusX extension
                                                 + BookingCategoryStatuses extension
                                                 + billingAmount, billingMethod, currentStatus fields
```

### Core Layer
```
lib/core/
├── theme/app_theme.dart
└── utils/
    ├── utils.dart (barrel)
    ├── responsive_utils.dart
    ├── snackbar_utils.dart
    ├── helpers/
    │   └── fakedata.dart                    → riderMockBookings (List<RiderBooking>) + riderMissions (List<Map>)
    └── validators/
        ├── validators.dart (barrel)
        ├── register_validator.dart
        ├── login_validator.dart
        ├── otp_validator.dart
        └── profile_validator.dart
```

### Assets
```
assets/images/
├── navbar/
│   ├── riderside/    → booking.svg, time.svg, profile.svg, wallet.svg, star.svg
│   └── merchant/     → booking.svg, orders.svg, profile.svg, menu.svg, star.svg
└── booking/
    └── banner.svg    → banner displayed in bookings tab header + booking detail screen
```

---

## Tech Stack
- **Flutter** 3.10+
- **Riverpod** 2.5.1
- **flutter_svg** 2.0.10+1
- **image_picker** 1.0.7
- **file_picker** 8.0.0+1
- **google_maps_flutter** (in pubspec, not yet used)
- **camera** (in pubspec, not yet used)
