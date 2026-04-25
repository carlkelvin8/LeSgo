# Widget Usage & Code Flow Documentation - Lezgo RIDERSIDE

## Overview

The RIDERSIDE application demonstrates a **modern, component-based UI architecture** with a focus on reusability, smooth animations, and responsive design. The widget structure is designed to be simple yet scalable, using composition patterns and state-driven UI updates.

## Widget Organization

### Directory Structure

presentation/widgets/
├── auth/                          # Authentication-related widgets
│   ├── auth_illustration.dart
│   ├── auth_top_bar.dart
│   ├── welcome_content.dart
│   ├── login_content.dart
│   ├── register_content.dart
│   ├── rider_login_content.dart
│   └── merchant_login_content.dart
├── global/                        # Reusable app-wide widgets
│   ├── primary_button.dart
│   ├── custom_text_field.dart
│   ├── top_bar.dart
│   ├── home_header.dart           # Added Widget? action optional slot (e.g. logout icon)
│   ├── register_scaffold.dart
│   └── confirm_dialog.dart        # showConfirmDialog() — reusable confirmation alert
├── main/                          # Main screen widgets
│   ├── riderside/
│   │   ├── rider_bottom_nav_bar.dart     # SvgPicture.asset icons w/ ColorFilter tinting
│   │   ├── bookings/
│   │   │   ├── rider_swipe_accept_button.dart        # "Accepted" overlay + fixed threshold
│   │   │   ├── rider_bookings_header.dart            # SvgPicture.asset banner.svg (replaces placeholder)
│   │   │   ├── rider_booking_card.dart               # Optional onTap for detail navigation
│   │   │   ├── rider_bookings_list.dart              # onBookingTap callback → Navigator.push
│   │   │   ├── rider_booking_status_button.dart      # Gradient display tile, display-only, black text
│   │   │   ├── rider_booking_status_grid.dart        # 2-col grid, iterates category.statuses
│   │   │   └── rider_booking_detail_info.dart        # Logo + booking info + billing rows
│   │   ├── history/
│   │   │   ├── rider_history_dashboard_card.dart
│   │   │   ├── rider_history_filter_tabs.dart
│   │   │   ├── rider_history_booking_card.dart
│   │   │   └── rider_history_bookings_list.dart
│   │   ├── profile/
│   │   │   ├── rider_profile_header.dart
│   │   │   ├── rider_profile_info_section.dart
│   │   │   └── rider_profile_task_card.dart
│   │   ├── wallet/
│   │   │   ├── rider_wallet_card.dart
│   │   │   ├── rider_wallet_actions_section.dart
│   │   │   └── rider_wallet_action_item.dart
│   │   └── mission/
│   │       └── rider_mission_card.dart
│   └── merchantside/
│       ├── merchant_bottom_nav_bar.dart  # SvgPicture.asset icons + allowDrawingOutsideViewBox
│       └── merchant_home_header.dart
├── register/                      # Registration flow widgets
│   ├── rider/
│   │   ├── terms_and_conditions/
│   │   ├── phone_verification/
│   │   ├── info/
│   │   └── complete/
│   └── merchant/
│       ├── info/
│       └── register_complete/
└── widgets.dart                   # Central barrel file (exports ALL widgets, 50+ exports)
```

**Organization Principles:**
- **Feature-based**: Widgets grouped by feature (auth, register, main/riderside, main/merchantside)
- **Anti-Monolith Componentization**: Screens are never built as a single massive file. They are broken into independent sections.
- **Global reusables**: Common components in `global/`
- **Centralized imports**: ALL widgets are exported via `widgets.dart` — screens import **only** the barrel file, never individual widget files
- **Composition layers**: Small primitives → section widgets → composite widgets
  - Example: `RiderWalletActionItem` → `RiderWalletActionsSection` → `RiderWalletView`
  - Example: `RiderMissionCard` → `RiderMissionView`

## Merchantside Menu Widget Updates (Latest)

### New/Updated Shared Widgets

- `MerchantFormLayout`
  - supports `stickyBottomAction` for fixed bottom action bar while form content scrolls
- `MerchantFormActionButtonsSection`
  - reused as sticky action for Add/Edit/Category screens
- `SectionSpacer`
  - standard vertical spacing primitive for menu forms
- `MerchantItemHeroSection`
  - reusable hero block in edit-item screen

### Screen Composition Pattern (Menu Forms)

All merchant menu screens now follow:

1. `MerchantFormLayout(formKey: ..., stickyBottomAction: ...)`
2. section widgets in `children`
3. no inline giant scaffold/form boilerplate

### Export Policy Update

For merchantside menu widgets, local menu `index.dart` barrel files were removed and exports were centralized in `widgets/widgets.dart`.

Removed:
- `main/merchantside/menu/shared/index.dart`
- `main/merchantside/menu/add_menu/index.dart`
- `main/merchantside/menu/edit_menu/index.dart`
- `main/merchantside/menu/add_category/index.dart`

Result:
- screens import from central `widgets.dart`
- consistent barrel strategy across the app

### Centralized Imports via Barrel File

All widgets are re-exported from a single `widgets.dart` barrel file. Screens **must** import from the barrel file rather than individual widget files.

```dart
// ✅ Correct — centralized barrel import
import '../../widgets/widgets.dart';

// ❌ Wrong — direct widget file import
import '../../widgets/main/riderside/wallet/rider_wallet_card.dart';
import '../../widgets/main/riderside/wallet/rider_wallet_actions_section.dart';
```

> [!IMPORTANT]
> When adding a new widget, always add its export to `widgets.dart` to keep the barrel file complete.

## Widget Categories

### 1. Global Widgets (`widgets/global/`)

Core reusable components used throughout the application.

#### Primary Button Widget

**File:** `global/primary_button.dart`

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.spacing(context, 52);
    final borderRadius = BorderRadius.circular(
      ResponsiveUtils.spacing(context, 12),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ??
              (backgroundColor == null
                  ? const LinearGradient(
                      colors: [Color(0xFF9B59F0), Color(0xFF5F2D82)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null),
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? const Color(0xFF5F2D82))
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onPressed,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.zero,
          child: isLoading
              ? CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
```

**Features:**
- **Gradient Support**: Default gradient or custom colors
- **Loading State**: Built-in loading indicator
- **Responsive**: Adapts to screen size
- **Elevated Design**: Shadow effects for depth
- **Customizable**: Multiple styling options

**Usage Examples:**

```dart
// Default gradient button
PrimaryButton(
  text: 'Login',
  onPressed: () => handleLogin(),
)

// Custom color button
PrimaryButton(
  text: 'Submit',
  onPressed: () => submit(),
  backgroundColor: Colors.green,
)

// Loading state
PrimaryButton(
  text: 'Logging in...',
  isLoading: true,
  onPressed: null,
)

// Custom width
PrimaryButton(
  text: 'Skip',
  width: 120,
  onPressed: () => skip(),
)
```

#### Custom Text Field Widget

**File:** `global/custom_text_field.dart`

```dart
class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.spacing(context, 12),
        ),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscureText,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
```

**Features:**
- **Password Toggle**: Show/hide password functionality
- **Responsive Design**: Adapts padding and sizing
- **Clean Styling**: Borderless with container decoration
- **Keyboard Support**: Custom keyboard types
- **Validator Support**: Red border on validation error (no error text shown)
- **Error Border**: Uses `Future.microtask` in validator to update border color without setState-during-build issues

**Current Implementation:**
```dart
class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
}
```

The validator works by:
1. `Form.validate()` calls each field's validator
2. Validator returns error string (or null)
3. `Future.microtask` updates `_errorMessage` state → border turns red
4. Error text is hidden (height: 0, fontSize: 0) — only red outline shown

**Usage Examples:**

```dart
// With validator (registration form)
CustomTextField(
  hintText: 'First Name',
  controller: firstNameController,
  validator: RegisterValidator.firstName,
)

// Password field
CustomTextField(
  hintText: 'Password',
  isPassword: true,
  controller: passwordController,
)

// Email field
CustomTextField(
  hintText: 'Email',
  keyboardType: TextInputType.emailAddress,
  controller: emailController,
  validator: RegisterValidator.email,
)
```

#### Home Header Widget

**File:** `global/home_header.dart`

```dart
class HomeHeader extends ConsumerWidget {
  final bool showBackButton;
  final Color backgroundColor;
  final Color logoColor;
  final Color borderColor;
  final Widget? action;         // Optional right-side action slot

  const HomeHeader({
    super.key,
    this.showBackButton = false,
    this.backgroundColor = Colors.white,
    this.logoColor = const Color(0xFF5F2D82),
    this.borderColor = const Color(0xFFEEEEEE),
    this.action,
  });
// ... 
}
```

**Features:**
- **Dynamic Styling**: Color properties to adapt to various backgrounds (e.g., solid white for main screens, transparent for the mission tab).
- **Optional Back Button**: Toggable based on nesting level.
- **Optional Action Slot**: `Widget? action` renders right-aligned via `Align(alignment: Alignment.centerRight)` inside the internal `Stack`. Pass any widget (icon button, avatar, etc.). If `null`, nothing renders.

**Usage — Logout Icon on Profile Tab:**
```dart
HomeHeader(
  action: currentNav == RiderNavType.profile
      ? GestureDetector(
          onTap: () => _showLogoutDialog(context, ref),
          child: const Icon(
            Icons.exit_to_app_rounded,
            color: Color(0xFFE53935),
            size: 26,
          ),
        )
      : null,
)
```

#### Confirm Dialog

**File:** `global/confirm_dialog.dart`

A reusable confirmation dialog function exported alongside widgets.

```dart
Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color confirmColor = const Color(0xFFE53935),
  required VoidCallback onConfirm,
})
```

**Features:**
- `RoundedRectangleBorder` with `borderRadius: 16`
- **Cancel** button: grey text, dismisses dialog
- **Confirm** button: bold, uses `confirmColor` (default red), dismisses then runs `onConfirm`
- Fully parametric: title, message, button labels, and confirm color are all configurable

**Usage:**
```dart
showConfirmDialog(
  context: context,
  title: 'Logout',
  message: 'Are you sure you want to logout?',
  confirmLabel: 'Logout',
  onConfirm: () {
    ref.read(authViewProvider.notifier).state = AuthView.welcome;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  },
);

// Another usage example
showConfirmDialog(
  context: context,
  title: 'Delete Order',
  message: 'This action cannot be undone.',
  confirmLabel: 'Delete',
  confirmColor: Colors.red,
  onConfirm: () => ref.read(ordersProvider.notifier).delete(id),
);
```

### 2. Authentication Widgets (`widgets/auth/`)

#### Auth Top Bar Widget

**File:** `auth/auth_top_bar.dart`

```dart
class AuthTopBar extends ConsumerWidget {
  const AuthTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    final isWelcome = authView == AuthView.welcome;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Centered content (text or logo)
          Align(
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (authView) {
                AuthView.login => const LoginText(),
                AuthView.riderLogin || 
                AuthView.merchantLogin => SvgPicture.asset(
                  'assets/images/Logo.svg',
                  height: ResponsiveUtils.imageHeight(context, 40),
                ),
                AuthView.register => const RegisterText(),
                AuthView.welcome => const WelcomeText(),
              },
            ),
          ),

          // Animated back button (left side)
          Positioned(
            left: 0,
            child: AnimatedOpacity(
              opacity: !isWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedSlide(
                offset: !isWelcome ? Offset.zero : const Offset(-0.5, 0),
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: isWelcome,
                  child: GestureDetector(
                    onTap: () {
                      // Handle back navigation
                      if (authView == AuthView.riderLogin ||
                          authView == AuthView.merchantLogin) {
                        ref.read(authViewProvider.notifier).state = 
                            AuthView.login;
                      } else {
                        ref.read(authViewProvider.notifier).state = 
                            AuthView.welcome;
                      }
                    },
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: ResponsiveUtils.imageHeight(context, 36),
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Features:**
- **State-Driven Content**: Different text/logo based on view
- **Animated Back Button**: Smooth opacity and slide animations
- **Smart Navigation**: Context-aware back button behavior
- **Centered Layout**: Stack-based positioning

**Animation Details:**
- Fade + slide transitions for content changes
- Opacity + slide for back button appearance
- 300-400ms duration for smooth feel
- `IgnorePointer` prevents interaction when hidden

#### Auth Illustration Widget

**File:** `auth/auth_illustration.dart`

```dart
class AuthIllustration extends ConsumerWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    final isRiderLogin = authView == AuthView.riderLogin || 
                         authView == AuthView.merchantLogin;

    return Container(
      width: ResponsiveUtils.spacing(context, 340),
      height: ResponsiveUtils.spacing(context, 340),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2F2F7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: isRiderLogin
              ? SvgPicture.asset(
                  'assets/images/Lesgo.svg',
                  key: const ValueKey('lesgo_illustration'),
                  height: ResponsiveUtils.imageHeight(context, 280),
                )
              : SvgPicture.asset(
                  'assets/images/Logo.svg',
                  key: const ValueKey('logo_illustration'),
                  height: ResponsiveUtils.imageHeight(context, 140),
                ),
        ),
      ),
    );
  }
}
```

**Features:**
- **State-Driven Visuals**: Different SVG based on auth view
- **Circular Container**: Soft background for illustrations
- **Fade + Scale Animation**: Smooth transitions between images
- **Responsive Sizing**: Adapts to screen dimensions

**Animation Pattern:**
- Uses `AnimatedSwitcher` for smooth transitions
- `ValueKey` helps AnimatedSwitcher detect changes
- Combined fade and scale for polished effect
- 500ms duration for luxurious feel

#### Content Widgets

**Welcome Content**

```dart
class WelcomeContent extends ConsumerWidget {
  const WelcomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('welcome_buttons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Login',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.login,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Register',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.register,
        ),
      ],
    );
  }
}
```

**Login Content**

```dart
class LoginContent extends ConsumerWidget {
  const LoginContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('login_buttons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Merchant',
          onPressed: () => ref.read(authViewProvider.notifier).state =
              AuthView.merchantLogin,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Rider',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.riderLogin,
        ),
      ],
    );
  }
}
```

**Rider Login Content**

```dart
class RiderLoginContent extends StatefulWidget {
  const RiderLoginContent({super.key});

  @override
  State<RiderLoginContent> createState() => _RiderLoginContentState();
}

class _RiderLoginContentState extends State<RiderLoginContent> {
  bool isRememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('rider_login_form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          hintText: 'Email/Phone',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        CustomTextField(
          hintText: 'Password',
          isPassword: true,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        
        // Remember me + Forgot password row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isRememberMe,
                  onChanged: (value) {
                    setState(() {
                      isRememberMe = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: const Color(0xFF5F2D82),
                ),
                Text('Remember for 30 days'),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Forgot Password
              },
              child: Text('Forgot Password?'),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        PrimaryButton(
          text: 'Log In',
          onPressed: () {
            // TODO: Perform Login
          },
        ),
      ],
    );
  }
}
```

**Content Widget Patterns:**
- Simple navigation buttons (Welcome, Login)
- Full forms with local state (RiderLogin, MerchantLogin)
- Unique `ValueKey` for AnimatedSwitcher
- `mainAxisSize.min` for compact layouts

### 3. Global Shared Widgets (`widgets/global/`)

#### TopBar Widget

**File:** `global/top_bar.dart`

Reusable header bar with back button and centered title, used across registration screens.

```dart
class TopBar extends StatelessWidget {
  final String title;
  final Widget? centerWidget;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
}
```

#### RegisterScaffold Widget

**File:** `global/register_scaffold.dart`

Shared scaffold layout used across all registration screens. Provides consistent structure:
- White background + SafeArea
- Sticky TopBar header with back navigation
- Scrollable body content area
- Optional sticky bottom widget (e.g., Continue button)

```dart
class RegisterScaffold extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget body;
  final Widget? bottomWidget;
  final double headerBottomSpacing;
}
```

**Usage:**
```dart
RegisterScaffold(
  title: 'Register',
  headerBottomSpacing: 24,
  body: Form(...),
  bottomWidget: PrimaryButton(text: 'Continue', onPressed: ...),
)
```

**Note:** RegisterScreen (terms) does NOT use RegisterScaffold because its layout uses `Expanded` for the scrollable terms content, which doesn't work inside `SingleChildScrollView`.

### 4. Terms and Conditions Widgets (`register/terms_and_conditions/`)

Three stateless widgets split from the original monolithic `TermsAndConditionsContent`:

| Widget | Purpose |
|--------|---------|
| `TermsHeader` | "Terms and Conditions" title text |
| `TermsScrollableContent` | Scrollable container with terms text + purple accent line |
| `TermsAcceptanceCheckbox` | Checkbox row with "I agree" text. Takes `value` + `onChanged` |

**Logic lives in RegisterScreen** — it reads `termsAcceptedProvider`, toggles checkbox state, and navigates on Continue.

### 5. Phone Verification Widgets (`register/phone_verification/`)

| Widget | Purpose |
|--------|---------|
| `PhoneVerificationIllustration` | Illustration image |
| `SectionLabel` | Section heading text |
| `PhoneInputField` | Phone number input with +63 prefix |
| `SendOTPButton` | "Send OTP" button with loading state |
| `ResendOTPButton` | "Resend OTP" link button |
| `VerificationCodeSection` | "Verification Code" label |
| `OTPInputBoxes` | 4 individual OTP digit input boxes |
| `PhoneVerificationForm` | **Composite** — groups SectionLabel, PhoneInputField, SendOTPButton/ResendOTPButton, OTPInputBoxes |

**PhoneVerificationForm** params:
```dart
class PhoneVerificationForm extends StatelessWidget {
  final TextEditingController phoneController;
  final List<TextEditingController> otpControllers;
  final bool otpSent;
  final bool isLoading;
  final bool isPhoneNumberValid;
  final VoidCallback onSendOTP;
  final VoidCallback onResendOTP;
}
```

### 6. Registration Info Widgets (`register/info/`)

| Widget | Purpose |
|--------|---------|
| `InfoIllustration` | Registration illustration image |
| `InfoMessage` | Instructional message text |
| `InfoFormFields` | Groups all 4 text fields (firstName, lastName, birthday, email) with validators |
| `SelfieUploadBox` | Camera upload button with image preview. Shows red on error |
| `SelfieUploadSection` | Label + SelfieUploadBox combo |
| `FileUploadBox` | File picker button with filename display. Shows red on error |
| `DocumentUploadSection` | Label + FileUploadBox combo |
| `DocumentUploadList` | **Composite** — groups all 6 DocumentUploadSections |
| `InfoSectionLabel` | Section heading |
| `SubmitInfoText` | Info text below submit button |

#### Upload Widget Error Pattern

Upload widgets accept a `showError` parameter to show red outlines when validation fails on submit:

```dart
// FileUploadBox
border: Border.all(
  color: (showError && filePath == null) ? Colors.red.shade300 : Colors.black26,
)

// SelfieUploadBox
color: (showError && imagePath == null) ? Colors.red.shade400 : Color(0xFF5F2D82),
```

This is necessary because upload widgets are NOT `TextFormField`s — `Form.validate()` has no effect on them. The `hasAttemptedSubmit` state from the controller triggers error display.

**DocumentUploadList** params:
```dart
class DocumentUploadList extends StatelessWidget {
  // 6 upload callbacks
  final VoidCallback onUploadResume;
  final VoidCallback onUploadBarangayClearance;
  // ... etc
  // 6 loading flags, 6 file paths, 1 showError flag
}
```

### 9. Bottom Nav Bar — SVG Icons

Both `RiderBottomNavBar` and `MerchantBottomNavBar` use `SvgPicture.asset` with `ColorFilter` for tintable active/inactive states.

**Key Technique:**
```dart
SvgPicture.asset(
  svgAsset,
  width: iconSize,
  height: iconSize,
  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  allowDrawingOutsideViewBox: true,  // Required on merchant icons to prevent clipping
)
```

- **Active color**: `Color(0xFF5F2D82)` (brand purple)
- **Inactive color**: `Color(0xFF9E9E9E)` (grey)
- `allowDrawingOutsideViewBox: true` — needed when the SVG has a tight internal `clipPath`; without this, icons with tight viewport definitions get clipped

**Riderside SVG mapping** (`assets/images/navbar/riderside/`):

| Tab | SVG File |
|-----|----------|
| Bookings | `booking.svg` |
| History | `time.svg` |
| Profile | `profile.svg` |
| Wallet | `wallet.svg` |
| Mission | `star.svg` |

**Merchantside SVG mapping** (`assets/images/navbar/merchant/`):

| Tab | SVG File |
|-----|----------|
| Book | `booking.svg` |
| Orders | `orders.svg` |
| Profile | `profile.svg` |
| Menu | `menu.svg` |
| Mission | `star.svg` |

### 10. Swipe Accept Button (`rider_swipe_accept_button.dart`)

**File:** `main/riderside/bookings/rider_swipe_accept_button.dart`

Draggable slider that accepts a booking when thumb is dragged past a threshold.

**Key Implementation Details:**
```dart
// Threshold: 75% of available drag range (NOT total bar width)
final threshold = (maxWidth - thumbWidth) * 0.75;

// Clamp drag within valid range
_dragPosition = (_dragPosition + delta.dx).clamp(0.0, maxWidth - thumbWidth);

// Accept on release if past threshold
if (_dragPosition >= threshold) {
  setState(() { _isAccepted = true; });
}
```

**"Accepted" State Display:**
```dart
if (_isAccepted)
  const Center(child: Text('Accepted', style: TextStyle(...)))
else
  // Swipe hint text (arrow + label)
```

**Why `(maxWidth - thumbWidth) * 0.75` and not `maxWidth * 0.75`:**
- The thumb can only travel `maxWidth - thumbWidth` pixels (it stops before the right edge)
- Using `maxWidth * 0.75` would set a threshold the thumb physically cannot reach

## Widget Composition Patterns

### 1. Single Screen, Multiple Views Pattern

The app uses one screen with state-driven view switching:

```dart
class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed components
            const AuthTopBar(),
            const AuthIllustration(),
            
            // Dynamic component based on state
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

**Benefits:**
- Shared layout components (top bar, illustration)
- Smooth transitions with AnimatedSwitcher
- No route management overhead
- Consistent spacing and animations

### 2. State-Driven Animation Pattern

```dart
// Illustration changes based on state
AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  },
  child: isRiderLogin
      ? SvgPicture.asset('lesgo.svg', key: ValueKey('lesgo'))
  child: isRiderLogin
      ? SvgPicture.asset('lesgo.svg', key: ValueKey('lesgo'))
      : SvgPicture.asset('logo.svg', key: ValueKey('logo')),
)
```

### 7. Merchant Widgets (`register/merchant/`)

#### Info & Uploads
*   `MerchantInfoFormFields`: Validated text fields (Restaurant Name, Address, etc.).
*   `MerchantDocumentUploadList`: 6 upload slots (Selfie, Valid ID, Signature, 3 Permits).
*   **FileUploadBox**: Reused `MerchantFileUploadBox` styling.

#### Completion Screen (`register/merchant/register_complete/`)
Modular widgets for the success screen:
*   `MerchantCompleteHeader`: "Registration Submitted" title.
*   `MerchantCompleteIllustration`: Success SVG.
*   `MerchantCompleteInfoCard`: Displays summary data using state getters.
*   `MerchantCompleteActionButtons`: "Go to Login" button.

### 8. Rider Complete Widgets (`register/rider/complete/`)
Similar modular structure:
*   `HeaderSection`, `IllustrationSection`, `InfoCardSection`, `ActionButtonsSection`.
```

**Key Elements:**
- `AnimatedSwitcher` for automatic transitions
- `ValueKey` to identify different children
- Composite animations (fade + scale)
- State determines which widget to show

### 3. Conditional Visibility Pattern

```dart
AnimatedOpacity(
  opacity: !isWelcome ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: AnimatedSlide(
    offset: !isWelcome ? Offset.zero : const Offset(-0.5, 0),
    duration: const Duration(milliseconds: 300),
    child: IgnorePointer(
      ignoring: isWelcome,
      child: BackButton(),
    ),
  ),
)
```

**Features:**
- `AnimatedOpacity` for fade in/out
- `AnimatedSlide` for movement
- `IgnorePointer` prevents interaction when hidden
- Compound animations for polish

### 4. Shared Scaffold Pattern (Registration Screens)

Registration screens use `RegisterScaffold` for consistent layout:

```dart
return RegisterScaffold(
  title: 'Register',
  headerBottomSpacing: 24,
  onBackPressed: () {
    controller.reset();
    Navigator.of(context).pop();
  },
  bottomWidget: PrimaryButton(text: 'Continue', onPressed: _verify),
  body: Column(
    children: [
      const SomeIllustration(),
      SomeForm(...),
    ],
  ),
);
```

### 5. Composite Widget Pattern

Small widgets compose into larger container widgets:

```
FileUploadBox → DocumentUploadSection → DocumentUploadList
SelfieUploadBox → SelfieUploadSection
PhoneInputField + OTPInputBoxes + SendOTPButton → PhoneVerificationForm
```

Screens use the composite widgets, reducing screen code significantly.

### 6. Thin Screen Pattern

Screens are purely presentational — they own controllers, compose widgets, and wire state:

```dart
class RegisterInfoScreen extends ConsumerStatefulWidget {
  // Owns: _formKey, 4 TextEditingControllers
  // initState: sync text → controller.updateXxx()
  // _handleSubmit: Form.validate() → controller.attemptSubmit()
  // build: ref.watch(), ref.listen(), compose widgets
}
```

## Code Flow

### User Flow: Welcome → Login → Rider Login

```
1. User sees Welcome Screen
   ↓
2. Taps "Login" button
   ↓
3. ref.read(authViewProvider.notifier).state = AuthView.login
   ↓
4. AuthScreen watches authViewProvider
   ↓
5. State change triggers rebuild
   ↓
6. AnimatedSwitcher transitions to LoginContent
   ↓
7. User taps "Rider" button
   ↓
8. State updates to AuthView.riderLogin
   ↓
9. AuthScreen rebuilds with RiderLoginContent
   ↓
10. Illustration and top bar animate accordingly
```

### State Update Flow

```dart
// Step 1: User interaction
PrimaryButton(
  text: 'Login',
  onPressed: () {
    // Step 2: Update state
    ref.read(authViewProvider.notifier).state = AuthView.login;
  },
)

// Step 3: Screen watches provider
final authView = ref.watch(authViewProvider);

// Step 4: UI updates based on state
AnimatedSwitcher(
  child: switch (authView) {
    AuthView.login => const LoginContent(),
    // ...
  },
)

// Step 5: Other widgets respond
AuthTopBar watches and shows back button
AuthIllustration watches and may change image
```

### Back Navigation Flow

```dart
PopScope(
  canPop: isWelcome,  // Only exit app from welcome
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop && !isWelcome) {
      // Internal navigation
      if (authView == AuthView.riderLogin) {
        ref.read(authViewProvider.notifier).state = AuthView.login;
      } else {
        ref.read(authViewProvider.notifier).state = AuthView.welcome;
      }
    } else if (didPop && isWelcome) {
      SystemNavigator.pop();  // Exit app
    }
  },
  child: /* screen */,
)
```

**Navigation Hierarchy:**
```
RiderLogin/MerchantLogin
    ↓ (back)
Login or Register
    ↓ (back)
Welcome
    ↓ (back)
Exit App
```

## Widget Export Pattern

**File:** `widgets.dart`

```dart
// Global widgets
export 'global/primary_button.dart';
export 'global/custom_text_field.dart';
export 'global/top_bar.dart';
export 'global/register_scaffold.dart';

// Auth widgets
export 'auth/auth_top_bar.dart';
export 'auth/auth_illustration.dart';
export 'auth/welcome_content.dart';
export 'auth/login_content.dart';
export 'auth/register_content.dart';
export 'auth/rider_login_content.dart';
export 'auth/merchant_login_content.dart';

// Register - Terms and Conditions
export 'register/terms_and_conditions/terms_header.dart';
export 'register/terms_and_conditions/terms_scrollable_content.dart';
export 'register/terms_and_conditions/terms_acceptance_checkbox.dart';

// Register - Phone Verification
export 'register/phone_verification/phone_input_field.dart';
export 'register/phone_verification/otp_input_boxes.dart';
export 'register/phone_verification/verification_code_section.dart';
export 'register/phone_verification/phone_verification_illustration.dart';
export 'register/phone_verification/send_otp_button.dart';
export 'register/phone_verification/resend_otp_button.dart';
export 'register/phone_verification/section_label.dart';
export 'register/phone_verification/phone_verification_form.dart';

// Register - Info
export 'register/info/info_illustration.dart';
export 'register/info/info_message.dart';
export 'register/info/info_form_fields.dart';
export 'register/info/selfie_upload_box.dart';
export 'register/info/selfie_upload_section.dart';
export 'register/info/file_upload_box.dart';
export 'register/info/document_upload_section.dart';
export 'register/info/document_upload_list.dart';
export 'register/info/info_section_label.dart';
export 'register/info/submit_info_text.dart';

// Main Interface - Bookings
export 'main/riderside/bookings/rider_booking_card.dart';
export 'main/riderside/bookings/rider_bookings_header.dart';
export 'main/riderside/bookings/rider_bookings_list.dart';
export 'main/riderside/bookings/rider_duty_toggle.dart';
export 'main/riderside/bookings/rider_swipe_accept_button.dart';
```

**Usage:**
```dart
// Single import for all widgets
import '../../widgets/widgets.dart';

// Use any exported widget
PrimaryButton(text: 'Submit')
CustomTextField(hintText: 'Email', validator: RegisterValidator.email)
RegisterScaffold(title: 'Register', body: ...)
DocumentUploadList(...)
```

## Responsive Design

### ResponsiveUtils Integration

All widgets use `ResponsiveUtils` for consistent sizing:

```dart
// Font sizes
Text(
  'Welcome',
  style: TextStyle(
    fontSize: ResponsiveUtils.fontSize(context, 16),
  ),
)

// Spacing
SizedBox(height: ResponsiveUtils.spacing(context, 14))

// Padding
EdgeInsets.symmetric(
  horizontal: ResponsiveUtils.spacing(context, 16),
)

// Image/Icon sizes
Icon(
  Icons.back,
  size: ResponsiveUtils.imageHeight(context, 36),
)

// Container sizes
Container(
  width: ResponsiveUtils.spacing(context, 340),
  height: ResponsiveUtils.spacing(context, 340),
)
```

### Device Breakpoints

```
Mobile (< 600px):
- Smaller fonts (85-95% of base)
- Tighter spacing (75-90% of base)
- Compact layouts

Tablet (600-1024px):
- Standard sizes (100% of base)
- Normal spacing
- More padding (48px horizontal)

Desktop (>= 1024px):
- Slightly larger fonts (110% of base)
- More generous spacing (120% of base)
- Maximum padding (64px horizontal)
```

## Animation Patterns

### 1. View Transition Animation

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  switchInCurve: Curves.easeInOut,
  switchOutCurve: Curves.easeInOut,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  },
  child: /* current view */,
)
```

**Characteristics:**
- Fade + slide combination
- 400ms duration
- EaseInOut curves for smoothness
- Vertical slide (downward entry)

### 2. Illustration Animation

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  },
  child: /* illustration SVG */,
)
```

**Characteristics:**
- Fade + scale combination
- 500ms duration (slower for visual impact)
- Scale creates zoom effect
- ValueKey identifies different children

### 3. Button Visibility Animation

```dart
AnimatedOpacity(
  opacity: visible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: AnimatedSlide(
    offset: visible ? Offset.zero : const Offset(-0.5, 0),
    duration: const Duration(milliseconds: 300),
    child: /* back button */,
  ),
)
```

**Characteristics:**
- Combined opacity + slide
- 300ms duration (quick for UI elements)
- Horizontal slide (from left)
- IgnorePointer prevents ghost taps

## Best Practices

### ✅ Do's

```dart
// Use const constructors
const PrimaryButton(text: 'Submit')

// Use ResponsiveUtils for all sizing
ResponsiveUtils.fontSize(context, 16)

// Give unique keys to AnimatedSwitcher children
child: SomeWidget(key: const ValueKey('unique_key'))

// Use ConsumerWidget for state access
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    // ...
  }
}

// Compose small widgets
Column(
  children: [
    const AuthTopBar(),
    const AuthIllustration(),
    const WelcomeContent(),
  ],
)
```

### ❌ Don'ts

```dart
// Don't use hardcoded values
fontSize: 16.0  // ❌ Wrong
ResponsiveUtils.fontSize(context, 16)  // ✅ Correct

// Don't forget keys in AnimatedSwitcher
AnimatedSwitcher(
  child: SomeWidget(),  // ❌ Won't animate properly
)
AnimatedSwitcher(
  child: SomeWidget(key: ValueKey('id')),  // ✅ Correct
)

// Don't nest AnimatedSwitchers unnecessarily
AnimatedSwitcher(
  child: AnimatedSwitcher(...)  // ❌ Usually wrong
)

// Don't use StatefulWidget when you don't need local state
class SimpleDisplay extends StatefulWidget  // ❌ Overkill
class SimpleDisplay extends StatelessWidget  // ✅ Simpler
```

## Performance Optimization

### 1. Const Constructors

```dart
✅ const PrimaryButton(text: 'Login')
✅ const SizedBox(height: 16)
✅ const WelcomeContent()
```

### 2. Extract Static Widgets

```dart
// Extract unchanging parts
static const _topBar = AuthTopBar();
static const _illustration = AuthIllustration();

// Reuse in build method
children: [
  _topBar,
  _illustration,
  dynamicContent,
]
```

### 3. Minimize Rebuilds

```dart
// Watch only what you need
final authView = ref.watch(authViewProvider);

// Don't watch if you only need to read
ref.read(authViewProvider.notifier).state = newValue;
```

## Testing Widgets

### Widget Test Example

```dart
void main() {
  testWidgets('PrimaryButton shows text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
  });

  testWidgets('PrimaryButton shows loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Loading',
            isLoading: true,
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

## Comparison with FRONTEND

| Aspect | FRONTEND | RIDERSIDE |
|--------|----------|-----------|
| **Widget Count** | High (many features) | 30+ widgets (growing) |
| **Complexity** | Complex compositions | Multi-layer compositions |
| **Navigation** | Route-based | State-based (auth) + Navigator.push (register) |
| **Animations** | Varied | Consistent patterns (auth) |
| **Organization** | Feature folders | Feature folders with composition layers |
| **Reusability** | Many shared widgets | Shared scaffolds, upload widgets, form widgets |

## Conclusion

The RIDERSIDE widget architecture demonstrates **clean, modern Flutter development** with:

- ✅ **Widget Composition**: Small primitives → sections → composite widgets
- ✅ **Thin Screens**: Screens compose widgets and wire state — no business logic
- ✅ **State-Driven UI**: UI responds to state changes automatically
- ✅ **Validation Pattern**: Red outlines on text fields (via Form.validate) and upload widgets (via showError prop)
- ✅ **Shared Layouts**: RegisterScaffold, TopBar for consistent screen structure
- ✅ **Responsive Design**: All sizing via ResponsiveUtils
- ✅ **Scalable Structure**: Easy to add new features following established patterns
