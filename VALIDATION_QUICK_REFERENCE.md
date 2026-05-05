# 🚀 Validation Quick Reference Guide

**Quick reference for using the validation system**

---

## 📱 FRONTEND VALIDATION

### **Import Validators**:
```dart
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/presentation/widgets/common/common_widgets.dart';
```

### **Common Validators**:

```dart
// Email
Validators.email(value)

// Phone (Philippine)
Validators.phone(value)

// Email or Phone
Validators.emailOrPhone(value)

// Password (strong)
Validators.password(value)

// Password confirmation
Validators.confirmPassword(value, passwordValue)

// Name
Validators.name(value, fieldName: 'First Name')

// Required field
Validators.required(value, fieldName: 'Field Name')

// Number
Validators.number(value, min: 0, max: 100)

// Price
Validators.price(value)

// URL
Validators.url(value)

// Address
Validators.address(value)
```

### **Using ValidatedTextField**:

```dart
ValidatedTextField(
  label: 'Email',
  hint: 'Enter your email',
  controller: emailController,
  validator: Validators.email,
  keyboardType: TextInputType.emailAddress,
)
```

### **Using PasswordField**:

```dart
PasswordField(
  label: 'Password',
  hint: 'Enter your password',
  controller: passwordController,
  validator: Validators.password,
  showStrengthIndicator: true,
)
```

### **Using PasswordConfirmField**:

```dart
PasswordConfirmField(
  label: 'Confirm Password',
  controller: confirmPasswordController,
  passwordController: passwordController,
)
```

---

## 🔧 BACKEND VALIDATION

### **Using Custom Validation Rules**:

```php
use App\Rules\PhilippinePhone;
use App\Rules\StrongPassword;

// In controller or form request
$request->validate([
    'phone' => ['required', new PhilippinePhone],
    'password' => ['required', new StrongPassword, 'confirmed'],
]);
```

### **Creating Form Requests**:

```bash
# Generate form request
php artisan make:request StoreUserRequest
```

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Rules\PhilippinePhone;
use App\Rules\StrongPassword;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['required', new PhilippinePhone],
            'password' => ['required', new StrongPassword, 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Name is required.',
            'email.required' => 'Email is required.',
            'email.email' => 'Please enter a valid email address.',
            'email.unique' => 'This email is already registered.',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('name')) {
            $this->merge([
                'name' => $this->sanitizeString($this->name),
            ]);
        }
    }

    private function sanitizeString(?string $value): ?string
    {
        if ($value === null) return null;
        return trim(htmlspecialchars(strip_tags($value), ENT_QUOTES, 'UTF-8'));
    }
}
```

### **Using Form Requests in Controllers**:

```php
use App\Http\Requests\StoreUserRequest;

public function store(StoreUserRequest $request)
{
    // Validation already done
    $validated = $request->validated();
    
    $user = User::create($validated);
    
    return $this->success($user, 'User created successfully', 201);
}
```

---

## 🔒 VALIDATION RULES REFERENCE

### **Frontend Validators**:

| Validator | Purpose | Example |
|-----------|---------|---------|
| `email()` | Email format | `user@example.com` |
| `phone()` | Philippine phone | `09171234567` |
| `emailOrPhone()` | Email or phone | `user@example.com` or `09171234567` |
| `password()` | Strong password | `Password123!` |
| `confirmPassword()` | Password match | Must match password field |
| `name()` | Name format | `Juan Dela Cruz` |
| `required()` | Required field | Any non-empty value |
| `number()` | Numeric value | `123.45` |
| `price()` | Price format | `99.99` |
| `url()` | URL format | `https://example.com` |
| `address()` | Address format | `123 Main St, City` |
| `date()` | Date format | `2026-05-05` |
| `age()` | Age 18+ | Birth date |

### **Backend Validation Rules**:

| Rule | Purpose | Example |
|------|---------|---------|
| `PhilippinePhone` | Philippine phone | `09171234567` |
| `StrongPassword` | Strong password | `Password123!` |
| `required` | Required field | Any non-empty value |
| `string` | String type | `"text"` |
| `numeric` | Numeric type | `123.45` |
| `integer` | Integer type | `123` |
| `boolean` | Boolean type | `true` or `false` |
| `email` | Email format | `user@example.com` |
| `url` | URL format | `https://example.com` |
| `min:n` | Minimum value/length | `min:8` |
| `max:n` | Maximum value/length | `max:255` |
| `exists:table,column` | Database exists | `exists:users,id` |
| `unique:table,column` | Database unique | `unique:users,email` |
| `confirmed` | Field confirmation | `password_confirmation` |

---

## 📊 ERROR RESPONSE FORMATS

### **Frontend Error Display**:

```dart
// Automatic error display with ValidatedTextField
ValidatedTextField(
  label: 'Email',
  controller: emailController,
  validator: Validators.email,
  // Error automatically shown below field
)
```

### **Backend Error Response** (422):

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "name": [
      "Name is required."
    ],
    "email": [
      "Please enter a valid email address."
    ],
    "phone": [
      "The phone must be a valid Philippine phone number (e.g., 09171234567, +639171234567)."
    ],
    "password": [
      "The password must be at least 8 characters and contain at least one uppercase letter, one lowercase letter, one number, and one special character."
    ]
  }
}
```

---

## 🧪 TESTING

### **Test Backend Validation**:

```bash
# Test validation rules
cd BACKEND/lesgo-api
php test_validation.php

# Test API endpoint
curl -X POST http://localhost:8000/api/v1/partners/1/menu-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "menu_category_id": 1,
    "name": "Test Item",
    "price": 50.00
  }'
```

### **Test Frontend Validation**:

```dart
// In your test file
testWidgets('Email validation test', (WidgetTester tester) async {
  final controller = TextEditingController();
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ValidatedTextField(
          label: 'Email',
          controller: controller,
          validator: Validators.email,
        ),
      ),
    ),
  );
  
  // Test invalid email
  controller.text = 'invalid';
  await tester.pump();
  expect(find.text('Please enter a valid email address'), findsOneWidget);
  
  // Test valid email
  controller.text = 'user@example.com';
  await tester.pump();
  expect(find.text('Please enter a valid email address'), findsNothing);
});
```

---

## 🎯 COMMON PATTERNS

### **Login Form**:

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      ValidatedTextField(
        label: 'Email or Phone',
        controller: emailController,
        validator: Validators.emailOrPhone,
      ),
      PasswordField(
        label: 'Password',
        controller: passwordController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Submit form
          }
        },
        child: Text('Login'),
      ),
    ],
  ),
)
```

### **Registration Form**:

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      ValidatedTextField(
        label: 'First Name',
        controller: firstNameController,
        validator: (value) => Validators.name(value, fieldName: 'First Name'),
      ),
      ValidatedTextField(
        label: 'Email',
        controller: emailController,
        validator: Validators.email,
      ),
      ValidatedTextField(
        label: 'Phone',
        controller: phoneController,
        validator: Validators.phone,
      ),
      PasswordField(
        label: 'Password',
        controller: passwordController,
        validator: Validators.password,
        showStrengthIndicator: true,
      ),
      PasswordConfirmField(
        label: 'Confirm Password',
        controller: confirmPasswordController,
        passwordController: passwordController,
      ),
    ],
  ),
)
```

### **API Endpoint with Validation**:

```php
// routes/api.php
Route::post('/users', [UserController::class, 'store']);

// UserController.php
use App\Http\Requests\StoreUserRequest;

public function store(StoreUserRequest $request)
{
    $validated = $request->validated();
    $user = User::create($validated);
    return $this->success($user, 'User created successfully', 201);
}

// StoreUserRequest.php
public function rules(): array
{
    return [
        'name' => ['required', 'string', 'min:2', 'max:100'],
        'email' => ['required', 'email', 'unique:users,email'],
        'phone' => ['required', new PhilippinePhone],
        'password' => ['required', new StrongPassword, 'confirmed'],
    ];
}
```

---

## 📚 DOCUMENTATION

- **Complete Guide**: `VALIDATION_IMPROVEMENT_GUIDE.md`
- **Frontend Details**: `FRONTEND_VALIDATION_IMPLEMENTATION.md`
- **Backend Details**: `BACKEND_VALIDATION_IMPLEMENTATION.md`
- **Implementation Summary**: `VALIDATION_IMPLEMENTATION_COMPLETE.md`
- **Quick Reference**: `VALIDATION_QUICK_REFERENCE.md` (this file)

---

**Last Updated**: May 5, 2026  
**Status**: ✅ READY TO USE

