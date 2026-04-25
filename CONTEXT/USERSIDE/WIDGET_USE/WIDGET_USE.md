# Widget Usage & Code Flow Documentation - Lezgo Project

## Overview

This document describes the widget architecture, reusable component patterns, and code flow throughout the Lezgo application. The project emphasizes component reusability, composition, and consistent UI patterns.

## Widget Organization

### Directory Structure

```
presentation/widgets/
├── auth/              # Authentication-related widgets
│   ├── login/
│   ├── register/
│   └── shared/
├── booking/           # Booking feature widgets
│   ├── leseat/
│   ├── lestransport/
│   └── lesbuy/
├── drawer/            # Navigation drawer components
├── faq/               # FAQ section widgets
├── global/            # App-wide reusable widgets
│   ├── googlemaps/
│   └── common/
├── home/              # Home screen widgets
├── inbox/             # Messaging/inbox widgets
├── lespay/            # Payment feature widgets
├── location/          # Location-related widgets
├── missions/          # Missions/tasks widgets
├── profile/           # User profile widgets
├── transactions/      # Transaction history widgets
└── widgets.dart       # Central widget exports
```

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
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.buttonHeight(context);
    final fontSize = ResponsiveUtils.fontSize(context, 16);
    
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF5F2D82),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: isLoading
            ? CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(text),
      ),
    );
  }
}
```

**Usage:**
```dart
PrimaryButton(
  text: 'Login',
  onPressed: () => handleLogin(),
  isLoading: authState.isLoading,
  backgroundColor: Color(0xFF5F2D82),
)
```

**Features:**
- Built-in loading state
- Responsive sizing
- Customizable colors
- Disabled state handling

#### Section Header Widget

**File:** `global/section_header.dart`

```dart
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAllPressed != null)
            TextButton(
              onPressed: onSeeAllPressed,
              child: Text('See All'),
            ),
        ],
      ),
    );
  }
}
```

**Usage:**
```dart
SectionHeader(
  title: 'Quick Access',
  onSeeAllPressed: () => Navigator.push(...),
)
```

#### Custom Text Field

**File:** `global/custom_text_field.dart`

Standardized text input field with consistent styling.

**Usage Example:**
```dart
CustomTextField(
  controller: emailController,
  labelText: 'Email',
  hintText: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

### 2. Authentication Widgets (`widgets/auth/`)

#### Phone Number Field

**File:** `auth/register/number/phone_number_field.dart`

```dart
class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Color focusedBorderColor;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.hintText = '+63 XXX XXX XXXX',
    this.focusedBorderColor = const Color(0xFF5F2D82),
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_enforcePrefix);
  }

  void _enforcePrefix() {
    final text = widget.controller.text;
    if (!text.startsWith('+63 ')) {
      widget.controller.value = TextEditingValue(
        text: '+63 ',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }
  }
  
  // ... rest of implementation
}
```

**Features:**
- Auto-prefix enforcement (+63)
- Validation
- Custom styling
- Input formatting

#### Dual Action Buttons

**File:** `auth/register/dual_action_buttons.dart`

```dart
class DualActionButtons extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final Color? primaryColor;
  final bool isLoading;

  const DualActionButtons({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.primaryIcon,
    this.secondaryIcon,
    this.primaryColor,
    this.isLoading = false,
  });
  
  // ... implementation
}
```

**Usage:**
```dart
DualActionButtons(
  primaryText: 'Accept',
  secondaryText: 'Decline',
  onPrimaryPressed: () => acceptTerms(),
  onSecondaryPressed: () => declineTerms(),
  primaryIcon: Icons.check,
  isLoading: state.isLoading,
)
```

### 3. Home Screen Widgets (`widgets/home/`)

#### Quick Access Card

**File:** `home/quick_access_card.dart`

```dart
class QuickAccessCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const QuickAccessCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.fontSize(context, 36);
    final titleSize = ResponsiveUtils.fontSize(context, 16);
    final subtitleSize = ResponsiveUtils.fontSize(context, 10);
    final cardPadding = ResponsiveUtils.spacing(context, 16);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: ResponsiveUtils.imageHeight(context, 160),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                height: iconSize,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Usage:**
```dart
Row(
  children: [
    QuickAccessCard(
      iconPath: 'assets/images/leseat_icon.svg',
      title: 'LesEat',
      subtitle: 'Order food',
      onTap: () => navigateToLesEat(),
    ),
    SizedBox(width: 12),
    QuickAccessCard(
      iconPath: 'assets/images/lestransport_icon.svg',
      title: 'LesTransport',
      subtitle: 'Book a ride',
      onTap: () => navigateToLesTransport(),
    ),
  ],
)
```

#### Promo Card

**File:** `home/promo_card.dart`

Horizontal scrolling promotional cards for banners and offers.

### 4. Profile Widgets (`widgets/profile/`)

#### Profile Rewards Section

**File:** `profile/profile_rewards_section.dart`

```dart
class ProfileRewardsSection extends StatelessWidget {
  final String referralCode;
  final int points;

  const ProfileRewardsSection({
    super.key,
    required this.referralCode,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ProfileReferralCard(referralCode: referralCode),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ProfilePointsCard(points: points),
        ),
      ],
    );
  }
}
```

**Composition Pattern:**
- Combines multiple child widgets
- Manages layout and spacing
- Passes data to children

### 5. Booking Widgets (`widgets/booking/`)

#### Restaurant Menu Item Card

**File:** `booking/leseat/restaurant/menu_item_card.dart`

```dart
class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = ResponsiveUtils.cardPadding(context);
    final imageSize = ResponsiveUtils.cardImageSize(context, 120);
    final maxLines = ResponsiveUtils.cardDescriptionMaxLines(context);

    return InkWell(
      onTap: onTap ?? () {
        AppRouter.push(
          context,
          BookingRoutes.leseatMenuItemDetail,
          arguments: item,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                item.imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6. Google Maps Widgets (`widgets/global/googlemaps/`)

#### Fullscreen Map Overlay

**File:** `global/googlemaps/fullscreen_map_overlay.dart`

Complex widget for interactive map experiences.

```dart
class FullscreenMapOverlay extends ConsumerWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final Widget? mapWidget;
  final bool Function()? shouldShow;
  final bool showZoomControls;
  final bool showLocationButton;
  final Widget? customTopRightControls;
  final bool showSearchBar;
  final Future<void> Function(LatLng)? onAnimateToLocation;
  final Function(LatLng, String?, Map<String, String>)? onPlaceSelected;

  const FullscreenMapOverlay({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    this.mapWidget,
    this.shouldShow,
    this.showZoomControls = true,
    this.showLocationButton = true,
    this.customTopRightControls,
    this.showSearchBar = false,
    this.onAnimateToLocation,
    this.onPlaceSelected,
  });
  
  // ... implementation
}
```

**Features:**
- Map search functionality
- Zoom controls
- Current location detection
- Place selection
- Fullscreen toggle
- Customizable controls

## Widget Composition Patterns

### 1. Container Pattern

Build complex widgets from simpler ones:

```dart
class UserInfoCard extends StatelessWidget {
  final String name;
  final String birthday;
  final String email;
  final String phoneNumber;
  final Widget? avatarWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (avatarWidget != null) avatarWidget!,
          _buildInfoRow('Name', name),
          _buildInfoRow('Birthday', birthday),
          _buildInfoRow('Email', email),
          _buildInfoRow('Phone', phoneNumber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
```

### 2. Builder Pattern

Conditionally build UI based on state:

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    if (profileState.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (profileState.error != null) {
      return ErrorWidget(error: profileState.error!);
    }

    if (profileState.user == null) {
      return EmptyStateWidget(message: 'No user data');
    }

    return ProfileContent(user: profileState.user!);
  }
}
```

### 3. List Builder Pattern

Dynamic list generation:

```dart
class MissionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionsProvider).missions;

    return ListView.builder(
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return MissionCard(
          mission: mission,
          onTap: () => handleMissionTap(mission),
        );
      },
    );
  }
}
```

## Code Flow Patterns

### 1. Screen → Widget → Provider Flow

```
Step 1: User Interaction
LoginScreen (Screen)
    ↓
Step 2: Widget Captures Input
LoginForm (Widget)
    ↓
Step 3: Call Provider Method
ref.read(authProvider.notifier).login(request)
    ↓
Step 4: State Update
AuthNotifier updates AuthState
    ↓
Step 5: UI Rebuild
LoginScreen rebuilds with new state
```

### 2. Navigation Flow

```dart
// From Widget
onPressed: () {
  AppRouter.push(
    context,
    MainRoutes.home,
    arguments: userData,
  );
}

// AppRouter handles routing
class AppRouter {
  static Future<T?> push<T>(
    BuildContext context,
    String routeName,
    {Object? arguments}
  ) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
}
```

### 3. Form Validation Flow

```
User Input → Controller → Validation → Provider → State Update → UI Feedback
```

**Example:**
```dart
class PersonalInfoForm extends StatelessWidget {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (value) => 
              value?.isEmpty ?? true ? 'Required' : null,
          ),
          PrimaryButton(
            text: 'Continue',
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Submit to provider
                ref.read(registerProvider.notifier).updatePersonalInfo(...);
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### 4. Async Operation Flow

```dart
// In Provider
Future<void> fetchData() async {
  // 1. Set loading state
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 2. Perform async operation
    final data = await apiService.fetchData();
    
    // 3. Update state with data
    state = state.copyWith(
      data: data,
      isLoading: false,
    );
  } catch (e) {
    // 4. Handle errors
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

// In Widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final dataState = ref.watch(dataProvider);

  // 5. UI responds to state
  if (dataState.isLoading) {
    return LoadingIndicator();
  }

  if (dataState.error != null) {
    return ErrorView(error: dataState.error!);
  }

  return DataView(data: dataState.data);
}
```

## Widget Best Practices

### 1. Use Const Constructors

```dart
✅ const PrimaryButton(text: 'Submit')
❌ PrimaryButton(text: 'Submit')
```

### 2. Extract Reusable Widgets

```dart
✅ 
Widget _buildHeader() => HeaderWidget();
Widget _buildContent() => ContentWidget();

❌
// Everything in one massive build method
```

### 3. Responsive Design

Always use `ResponsiveUtils` for sizing:

```dart
✅ 
final fontSize = ResponsiveUtils.fontSize(context, 16);
final spacing = ResponsiveUtils.spacing(context, 12);

❌
final fontSize = 16.0;
final spacing = 12.0;
```

### 4. Widget Composition Over Inheritance

```dart
✅
class ProfileCard extends StatelessWidget {
  final Widget avatar;
  final Widget info;
  
  // Compose widgets
}

❌
class BaseCard extends StatelessWidget {}
class ProfileCard extends BaseCard {} // Inheritance
```

### 5. Named Parameters

```dart
✅
QuickAccessCard(
  iconPath: 'assets/icon.svg',
  title: 'Title',
  subtitle: 'Subtitle',
)

❌
QuickAccessCard('assets/icon.svg', 'Title', 'Subtitle')
```

## Common Widget Patterns

### 1. Loading State Pattern

```dart
if (state.isLoading) {
  return Center(child: CircularProgressIndicator());
}
```

### 2. Empty State Pattern

```dart
if (items.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        Text('No items found'),
      ],
    ),
  );
}
```

### 3. Error State Pattern

```dart
if (state.error != null) {
  return ErrorWidget(
    error: state.error!,
    onRetry: () => ref.read(provider.notifier).retry(),
  );
}
```

### 4. Conditional Widget Pattern

```dart
if (condition) WidgetA() else WidgetB()

// Or with null safety
if (condition) WidgetA(),

// Or in lists
Column(
  children: [
    AlwaysWidget(),
    if (showOptional) OptionalWidget(),
    AnotherWidget(),
  ],
)
```

## Widget Export Pattern

Central widget exports for easy imports:

**File:** `widgets.dart`

```dart
// Export all reusable widgets
export '../../WIDGET_USE/global/custom_text_field.dart';
export '../../WIDGET_USE/global/primary_button.dart';
export '../../WIDGET_USE/global/header.dart';
export '../../WIDGET_USE/global/section_header.dart';

// Google Maps widgets
export '../../WIDGET_USE/global/googlemaps/map_widget.dart';
export '../../WIDGET_USE/global/googlemaps/map_zoom_controls.dart';

// Auth widgets
export '../../WIDGET_USE/auth/login/social_login_button.dart';
export '../../WIDGET_USE/auth/register/birthday_field.dart';
export '../../WIDGET_USE/auth/register/dual_action_buttons.dart';

// And more...
```

**Usage:**
```dart
import '../../../widgets/widgets.dart';

// Now use any exported widget
PrimaryButton(text: 'Submit')
CustomTextField(controller: controller)
```

## Responsive Utilities

### ResponsiveUtils Usage

```dart
// Font sizes
ResponsiveUtils.fontSize(context, 16)

// Spacing
ResponsiveUtils.spacing(context, 12)

// Button heights
ResponsiveUtils.buttonHeight(context)

// Image heights
ResponsiveUtils.imageHeight(context, 200)

// Card padding
ResponsiveUtils.cardPadding(context)

// Horizontal padding
ResponsiveUtils.horizontalPadding(context)

// Screen dimensions
ResponsiveUtils.screenWidth(context)
ResponsiveUtils.screenHeight(context)
```

## Performance Optimization

### 1. Use const Widgets

```dart
const SizedBox(height: 16)
const Icon(Icons.check)
const Text('Static text')
```

### 2. Extract Complex Widgets

```dart
// Instead of rebuilding complex widget tree
class _ComplexSection extends StatelessWidget {
  // Widget tree
}
```

### 3. Use Keys When Needed

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ListItem(
      key: ValueKey(items[index].id),
      item: items[index],
    );
  },
)
```

## Accessibility

### Text Scaling

```dart
// Responsive utils handles text scaling
ResponsiveUtils.fontSize(context, baseSize)
```

### Semantic Labels

```dart
Semantics(
  label: 'Submit button',
  child: PrimaryButton(text: 'Submit'),
)
```

## Conclusion

The Lezgo project demonstrates excellent widget architecture with:
- **Reusability**: Common widgets extracted and shared
- **Composition**: Complex UIs built from simple components
- **Consistency**: Unified styling through utilities
- **Responsiveness**: Adaptive layouts for different screens
- **Maintainability**: Clear organization and patterns

By following these patterns, the codebase remains scalable and easy to understand for new developers joining the project.
