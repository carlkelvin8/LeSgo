# Company Information - TODO

## ⚠️ IMPORTANT: Update Before Launch

You need to update the following company information in the Privacy Policy and Terms of Service screens:

---

## 📝 Information Needed:

### 1. Company Details
- **Company Name:** LeSgo Philippines (or your registered business name)
- **Business Registration Number:** [Your DTI/SEC Registration Number]
- **Company Address:** [Complete address with building, street, barangay, city, province, ZIP]

### 2. Contact Information
- **Support Email:** support@lesgo.ph (or your actual email)
- **Privacy Email:** privacy@lesgo.ph (or your actual email)
- **Phone Number:** [Your customer support phone number]
- **Website:** [Your website URL if available]

### 3. Legal Information
- **Jurisdiction:** [City/Province where disputes will be resolved]
  - Example: "Makati City, Metro Manila, Philippines"
  - Example: "Cebu City, Cebu, Philippines"

---

## 📂 Files to Update:

### 1. Privacy Policy Screen
**File:** `lib/presentation/screens/legal/privacy_policy_screen.dart`

**Lines to update:**
- Line ~150: Email address (currently: privacy@lesgo.ph)
- Line ~151: Phone number (currently: [Your Phone Number])
- Line ~152-154: Company address

**Search for:**
```dart
'Email: privacy@lesgo.ph\n'
'Phone: [Your Phone Number]\n'
'Address: [Your Company Address]\n\n'
'LeSgo Philippines\n'
'[City, Province, ZIP Code]'
```

**Replace with your actual information**

---

### 2. Terms of Service Screen
**File:** `lib/presentation/screens/legal/terms_of_service_screen.dart`

**Lines to update:**
- Line ~140: Jurisdiction (currently: [Your City/Province])
- Line ~150: Email address (currently: support@lesgo.ph)
- Line ~151: Phone number (currently: [Your Phone Number])
- Line ~152-154: Company address

**Search for:**
```dart
'These terms are governed by the laws of the Republic of the Philippines. Any disputes shall be resolved in the courts of [Your City/Province], Philippines.'
```

**And:**
```dart
'Email: support@lesgo.ph\n'
'Phone: [Your Phone Number]\n'
'Address: [Your Company Address]\n\n'
'LeSgo Philippines\n'
'[City, Province, ZIP Code]'
```

**Replace with your actual information**

---

## ✅ Example (for reference):

### Example Company Info:
```
Company Name: LeSgo Philippines Inc.
DTI Registration: 1234567890
Address: Unit 123, ABC Building
         456 Main Street, Barangay San Antonio
         Makati City, Metro Manila 1200
         Philippines

Support Email: support@lesgo.ph
Privacy Email: privacy@lesgo.ph
Phone: +63 917 123 4567
Website: https://lesgo.ph

Jurisdiction: Makati City, Metro Manila, Philippines
```

### How it would look in Privacy Policy:
```dart
'Email: support@lesgo.ph\n'
'Phone: +63 917 123 4567\n'
'Address: Unit 123, ABC Building\n'
'         456 Main Street, Barangay San Antonio\n'
'         Makati City, Metro Manila 1200\n'
'         Philippines\n\n'
'LeSgo Philippines Inc.\n'
'DTI Registration: 1234567890'
```

---

## 🔍 How to Update:

### Option 1: Manual Update
1. Open `lib/presentation/screens/legal/privacy_policy_screen.dart`
2. Search for `[Your Phone Number]`
3. Replace with your actual phone number
4. Search for `[Your Company Address]`
5. Replace with your actual address
6. Repeat for `terms_of_service_screen.dart`

### Option 2: Find and Replace
1. Use your IDE's "Find in Files" feature
2. Search for: `[Your Phone Number]`
3. Replace with: Your actual phone number
4. Search for: `[Your Company Address]`
5. Replace with: Your actual address
6. Search for: `[Your City/Province]`
7. Replace with: Your actual jurisdiction

---

## 📋 Checklist:

- [ ] Update company name
- [ ] Update DTI/SEC registration number (if required)
- [ ] Update complete company address
- [ ] Update support email
- [ ] Update privacy email
- [ ] Update phone number
- [ ] Update jurisdiction
- [ ] Update website URL (if available)
- [ ] Review Privacy Policy with legal team
- [ ] Review Terms of Service with legal team
- [ ] Test navigation to both screens
- [ ] Verify all links work correctly

---

## ⚠️ Legal Disclaimer:

**IMPORTANT:** These Privacy Policy and Terms of Service templates are provided as a starting point. You should:

1. **Consult with a lawyer** to ensure compliance with:
   - Philippine Data Privacy Act (DPA) of 2012
   - E-Commerce Act (RA 8792)
   - Consumer Act of the Philippines (RA 7394)
   - Other applicable laws

2. **Customize the content** to match your actual business practices

3. **Keep them updated** as your business practices change

4. **Make them easily accessible** to users (already done via Settings screen)

---

## 📞 Need Help?

If you need help updating these files, you can:
1. Ask me to update them with your specific information
2. Hire a lawyer to review and customize the legal documents
3. Use online legal document services (ensure they comply with Philippine law)

---

**Last Updated:** April 18, 2026  
**Status:** ⚠️ Requires company information update before launch
