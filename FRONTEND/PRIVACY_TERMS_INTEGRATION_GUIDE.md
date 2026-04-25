# Privacy Policy & Terms of Service Integration Guide

## Where to Add Links

### 1. Registration Screen
**File:** `lib/presentation/screens/auth/steps/verification_screen.dart` or registration screen

**Add at the bottom of the form (before submit button):**

```dart
// Add this widget before the submit button
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'By continuing, you agree to our ',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF666666),
        ),
      ),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TermsOfServiceScreen(),
            ),
          );
        },
        child: const Text(
          'Terms',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const Text(
        ' and ',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF666666),
        ),
      ),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyScreen(),
            ),
          );
        },
        child: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  ),
)
```

**Import required:**
```dart
import '../../screens/legal/privacy_policy_screen.dart';
import '../../screens/legal/terms_of_service_screen.dart';
```

---

### 2. Profile/Settings Screen
**File:** `lib/presentation/screens/main/profile_screen.dart` or settings screen

**Add in the settings list:**

```dart
// Add these list items in your settings/profile screen
ListTile(
  leading: const Icon(
    Icons.privacy_tip_outlined,
    color: Color(0xFF5F2D82),
  ),
  title: const Text(
    'Privacy Policy',
    style: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
    ),
  ),
  trailing: const Icon(
    Icons.arrow_forward_ios,
    size: 16,
    color: Color(0xFF999999),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  },
),
const Divider(height: 1),
ListTile(
  leading: const Icon(
    Icons.description_outlined,
    color: Color(0xFF5F2D82),
  ),
  title: const Text(
    'Terms of Service',
    style: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
    ),
  ),
  trailing: const Icon(
    Icons.arrow_forward_ios,
    size: 16,
    color: Color(0xFF999999),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  },
),
```

---

### 3. About Screen (Optional)
**Create:** `lib/presentation/screens/main/about_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Logo
          Center(
            child: Image.asset(
              'assets/images/logo.png', // Update with your logo path
              height: 100,
            ),
          ),
          const SizedBox(height: 16),
          
          // App Name
          const Center(
            child: Text(
              'Lesgo',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Version
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Legal Section
          const Text(
            'Legal',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          
          // Privacy Policy
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: Color(0xFF5F2D82),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          
          // Terms of Service
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.description_outlined,
              color: Color(0xFF5F2D82),
            ),
            title: const Text(
              'Terms of Service',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Contact Section
          const Text(
            'Contact Us',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Email: support@lesgo.com\nPhone: +63 XXX XXX XXXX',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Quick Copy-Paste Imports

Add these imports to any file where you want to link to Privacy/Terms:

```dart
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
```

Or if you're in a different directory structure:

```dart
import 'package:lesgo/presentation/screens/legal/privacy_policy_screen.dart';
import 'package:lesgo/presentation/screens/legal/terms_of_service_screen.dart';
```

---

## Navigation Examples

### Simple Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PrivacyPolicyScreen(),
  ),
);
```

### With Named Routes (if you add to router)
```dart
Navigator.pushNamed(context, '/privacy-policy');
Navigator.pushNamed(context, '/terms-of-service');
```

---

## Styling Guidelines

All links use the existing design system:
- **Primary Color:** `#5F2D82` (Purple)
- **Font Family:** `TT Fors`
- **Link Style:** Underlined, bold (w600)
- **Body Text:** Regular (w400), gray (#666666)

---

## Checklist

- [ ] Add Privacy/Terms links to registration screen
- [ ] Add Privacy/Terms links to profile/settings screen
- [ ] Create About screen (optional)
- [ ] Test navigation to both screens
- [ ] Update contact information in both screens
- [ ] Review content with legal team
- [ ] Test on both iOS and Android

---

**Note:** These screens are already created and ready to use. Just add the navigation links in your existing screens.
