![alt text](image.png)# Code Flow Documentation - RIDERSIDE

This document outlines the execution flow of key features in the RIDERSIDE application, serving as a guide for developers to navigate the codebase.

## 1. Application Initialization

**Entry Point:** `lib/main.dart`

1.  `main()` function calls `runApp()`.
2.  `ProviderScope` initializes Riverpod state management.
3.  `LesgoApp` widget sets up `MaterialApp` with:
    *   Theme (Material 3, Custom Colors, TT Fors font).
    *   `home: const AuthScreen()` as the starting screen.

## 2. Authentication Flow

**Screen:** `lib/presentation/screens/auth/auth_screen.dart`
**State Provider:** `authViewProvider` in `lib/presentation/provider/auth/auth_provider.dart`

The `AuthScreen` acts as a single-page orchestrator that switches views based on the `authViewProvider` state.

### Flow Breakdown:

1.  **Initial State:** `AuthView.welcome`
    *   Displays `WelcomeContent` (Login/Register buttons).
    *   `AuthTopBar` shows back button (hidden).
    *   `AuthIllustration` shows "Logo.svg".

2.  **User Interaction (Navigation):**
    *   **Tap "Login"**: Updates provider to `AuthView.login`.
        *   `AnimatedSwitcher` transitions to `LoginContent`.
        *   Back button appears.
    *   **Tap "Register"**: Updates provider to `AuthView.register`.
        *   `AnimatedSwitcher` transitions to `RegisterContent`.
    *   **Tap "Rider" (in Login)**: Updates provider to `AuthView.riderLogin`.
    *   **Tap "Merchant" (in Login)**: Updates provider to `AuthView.merchantLogin`.

3.  **Back Navigation:**
    *   `PopScope` intercepts back gestures.
    *   If in `riderLogin` or `merchantLogin`, state resets to `login`.
    *   If in `login` or `register`, state resets to `welcome`.

## 3. Rider Registration Flow

**Entry Point:** Tap "Rider" in `RegisterContent`.
**Navigation:** `Navigator.push` to `RegisterScreen`.

### Step 1: Terms & Conditions
*   **File:** `lib/presentation/screens/register/rider/register_screen.dart`
*   **Widgets:** `TermsHeader`, `TermsScrollableContent`, `TermsAcceptanceCheckbox`.
*   **Logic:**
    1.  User reads terms.
    2.  Toggles checkbox -> Updates `termsAcceptedProvider`.
    3.  Tap "Continue" -> Checks provider -> Navigates to `RegisterPhoneVerificationScreen`.

### Step 2: Phone Verification
*   **File:** `lib/presentation/screens/register/rider/register_phone_verification_screen.dart`
*   **Controller:** `RegisterPhoneVerificationController`.
*   **Flow:**
    1.  User enters phone number.
    2.  Tap "Send OTP" -> Calls `controller.sendOTP()`.
    3.  Enter 4-digit OTP.
    4.  Tap "Verify" -> Calls `controller.verifyOTP()`.
    5.  If success -> Navigates to `RegisterInfoScreen`.

### Step 3: Information & Uploads
*   **File:** `lib/presentation/screens/register/rider/register_info_screen.dart`
*   **Controller:** `RegisterInfoController`.
*   **Flow:**
    1.  User fills text fields (Name, Birthday, Email).
        *   Screen listeners sync text to Controller.
    2.  User uploads documents (Selfie, License, Permits).
        *   Tap Upload -> Calls `controller.uploadResult()`.
        *   Controller uses `ImagePicker`/`FilePicker`.
    3.  Tap "SUBMIT":
        *   Screen calls `_formKey.currentState.validate()`.
        *   Screen calls `controller.attemptSubmit(isValid)`.
    4.  **Submission Logic:**
        *   Controller checks `isValid` (form) and `state.documents.isComplete`.
        *   If valid -> Sets `isSubmitted = true`.
        *   If invalid -> Sets `errorMessage` and `hasAttemptedSubmit = true` (triggering red borders).
    5.  **Navigation:**
        *   Screen listens to state.
        *   If `isSubmitted` is true -> Navigates to `RegisterCompleteScreen`.

### Step 4: Completion
*   **File:** `lib/presentation/screens/register/rider/register_complete_screen.dart`
*   **Display:**
    *   Shows success illustration.
    *   Displays summary of info (using `RegisterInfoState` getters).
    *   "Go to Login" button -> Returns to `AuthScreen`.

## 4. Merchant Registration Flow

**Entry Point:** Tap "Merchant" in `RegisterContent`.
**Navigation:** `Navigator.push` to `MerchantRegisterScreen`.

### Single-Screen Process
*   **File:** `lib/presentation/screens/register/merchant/merchant_register_screen.dart`
*   **Controller:** `MerchantRegisterInfoController`.
*   **Flow matches Rider Step 3 but combined:**
    1.  User fills Merchant Info (Restaurant Name, Owner Name, etc.).
    2.  User uploads Merchant Documents (Mayors Permit, DTI, etc.).
    3.  Tap "SUBMIT":
        *   Validates form and documents.
        *   Calls `controller.attemptSubmit()`.
    4.  **Navigation:**
        *   On success -> Navigates to `MerchantRegisterCompleteScreen`.

### Completion
*   **File:** `lib/presentation/screens/register/merchant/merchant_register_complete_screen.dart`
*   Same pattern as Rider completion, showing Merchant specific details.

## 5. Main Navigation Flow

**Entry Point:** Successful Login/Registration transitions to `RiderMainScreen`.
**State Provider:** `riderNavProvider` in `lib/presentation/provider/main/riderside/rider_main_nav_provider.dart`

### Stack-Based Navigation (StateNotifier)

`riderNavProvider` is a `StateNotifier<List<RiderNavType>>` — the list acts as a navigation stack with the last entry being the active tab.

```dart
class RiderNavNotifier extends StateNotifier<List<RiderNavType>> {
  RiderNavNotifier() : super(const [RiderNavType.bookings]);

  RiderNavType get current => state.last;

  void navigateTo(RiderNavType type) {
    if (state.last == type) return;                        // No-op if already active
    if (type == RiderNavType.bookings) {
      state = const [RiderNavType.bookings]; return;       // Bookings always resets stack
    }
    final filtered = state.where((t) => t != type).toList(); // Deduplicate
    state = [...filtered, type];                           // Push to top
  }

  bool pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1); return true;
    }
    return false;
  }
}
```

**Rules:**
- Tapping Bookings **always resets** the stack to `[bookings]` — back button exits the app from Bookings
- Tapping any other tab deduplicates first then pushes, so back traverses visited tabs in order
- Physical back button is intercepted by `PopScope` in `RiderMainScreen`

### Single Scaffold Routing

*   **Screen Component:** `RiderMainScreen`
*   **Navigation:** Uses a `Scaffold` with `RiderBottomNavBar`
    *   Top: `HomeHeader(action: ...)` — shows logout icon on Profile tab
    *   Body: `Expanded` containing the active view based on `navStack.last`
    *   Bottom: `RiderBottomNavBar`
*   **Back Handling via `PopScope`:**
    ```dart
    PopScope(
      canPop: navStack.length <= 1,       // Allow exit only at root
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(riderNavProvider.notifier).pop();
      },
    )
    ```
*   **Tabs / Views:**
    *   **Bookings (`RiderNavType.bookings`):** Default view. `RiderBookingsView` with custom header (skyline illustration, duty toggle) and swipeable booking cards.
    *   **History (`RiderNavType.history`):** Past bookings (`RiderHistoryView`).
    *   **Profile (`RiderNavType.profile`):** User details (`RiderProfileView`). Shows logout button in header.
    *   **Wallet (`RiderNavType.wallet`):** Balance and transactions (`RiderWalletView`) — wrapped in `SingleChildScrollView`.
    *   **Mission (`RiderNavType.mission`):** Missions and rewards (`RiderMissionView`). Full-screen background, `HomeHeader` overlayed.

### Views Are Not Monoliths
All views mapped by the navigation bar strictly adhere to an **anti-monolith rendering process**:
*   **Bookings Tab:** `RiderBookingsView` → `RiderBookingsHeader` (+ `RiderDutyToggle`) + `RiderBookingsList` (+ `RiderBookingCard` + `RiderSwipeAcceptButton`)
*   **Profile Tab:** `RiderProfileView` → `RiderProfileHeader` + `RiderProfileInfoSection`
*   **Wallet Tab:** `RiderWalletView` → `RiderWalletCard` + `RiderWalletActionsSection`
*   **Mission Tab:** `RiderMissionView` → maps list of missions to `RiderMissionCard`

## 6. Bookings Tab — Booking Detail Navigation Flow

**Entry Point:** Tapping a `RiderBookingCard` in the bookings list.

**Files involved:**
- `lib/presentation/widgets/main/riderside/bookings/rider_booking_card.dart`
- `lib/presentation/widgets/main/riderside/bookings/rider_bookings_list.dart`
- `lib/presentation/screens/main/riderside/views/rider_bookings_view.dart`
- `lib/presentation/screens/main/riderside/rider_booking_detail_screen.dart`

**Flow:**
1. `RiderBookingCard` has an optional `VoidCallback? onTap` — wraps the card in a `GestureDetector`
2. `RiderBookingsList` receives `ValueChanged<RiderBooking>? onBookingTap` and passes each booking's tap callback to its card
3. `RiderBookingsView` provides the `onBookingTap` handler:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => RiderBookingDetailScreen(booking: booking),
     ),
   );
   ```
4. `RiderBookingDetailScreen` (`ConsumerStatefulWidget`) receives the `RiderBooking` and:
   - Initializes `_currentStatus = widget.booking.currentStatus` in `initState`
   - Renders: `HomeHeader(showBackButton: true)` → banner SVG → `RiderBookingDetailInfo` → status section
5. **Status Grid**: `RiderBookingStatusGrid` iterates `booking.category.statuses` and renders `RiderBookingStatusButton` for each — display only, no tap, gradient color per status, active status has no special border
6. **Back navigation**: `HomeHeader`'s back button calls `Navigator.pop(context)`

## 7. Bookings Tab — Swipe Accept Flow

**File:** `lib/presentation/widgets/main/riderside/bookings/rider_swipe_accept_button.dart`

1.  User drags the thumb rightward inside `GestureDetector` (uses `LayoutBuilder` for `maxWidth`)
2.  Drag is clamped: `0 ≤ _dragPosition ≤ maxWidth - thumbWidth`
3.  When `_dragPosition >= (maxWidth - thumbWidth) * 0.75`:
    *   `_isAccepted = true` (set via `setState`)
    *   Thumb locks at end position
    *   Centered "Accepted" text replaces the swipe hint

## 7. Logout Flow

**Trigger:** Tapping the red `Icons.exit_to_app_rounded` icon in `HomeHeader.action` on the Profile tab.

**Flow:**
1.  `GestureDetector.onTap` calls `_showLogoutDialog(context, ref)`
2.  `showConfirmDialog(...)` is called — renders a native `AlertDialog` via `widgets/global/confirm_dialog.dart`
    *   **Cancel** → `Navigator.of(ctx).pop()` — dialog dismissed, no state change
    *   **Logout** → `Navigator.of(ctx).pop()` (close dialog), then:
        1.  `ref.read(authViewProvider.notifier).state = AuthView.welcome` — resets auth sub-view so landing is always Login/Register selection
        2.  `Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false)` — clears entire nav stack, lands on `AuthScreen`

**Applied to:** Both `RiderMainScreen` and `MerchantMainScreen`

## 8. Merchantside Menu Management Flow (Latest)

### Entry Points
- From `MerchantMainScreen` menu tab floating action:
    - `Add Menu` -> `MerchantMenuAddItemScreen`
    - `Add Category` -> `MerchantMenuAddCategoryScreen`
- From profile menu cards:
    - `Edit Menu` tap -> `MerchantMenuEditItemScreen(initialItem: item)`

### Shared Form Pattern
All three merchant menu forms now follow this flow:

1. Screen initializes form controller in `initState` (TextEditingController ownership).
2. Screen gets provider state/notifier via Riverpod.
3. `ref.listen(...)` handles side effects only:
     - Error -> `SnackBarUtils.showError(...)`
     - Submit success transition -> success snackbar + `Navigator.pop(...)`
4. UI renders via `MerchantFormLayout`:
     - Scrollable content in `children`
     - Sticky action buttons via `stickyBottomAction`

### Provider Input Flow (Add vs Edit)
- Add Item uses constant typed input:
    - `MerchantMenuItemFormInput.add()`
- Edit Item uses typed input built once in `initState`:
    - `MerchantMenuItemFormInput.edit(widget.initialItem)`

This avoids rebuilding ad hoc maps in `build()` and keeps provider keys stable.

### Category Dropdown Stability
The category section now guards against invalid selected values by:
- ensuring a selected value exists in the dropdown list before binding as `value`
- merging selected category into available items when needed

This prevents `DropdownButton` assertion crashes for out-of-list values.
