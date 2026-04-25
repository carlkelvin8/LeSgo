# Test Rider Accounts

This document contains test rider accounts for development and testing purposes.

## How to Create a Test Rider Account

### Option 1: Using PowerShell (Windows)
```powershell
.\create_test_rider.ps1
```

### Option 2: Using Bash (Linux/Mac)
```bash
chmod +x create_test_rider.sh
./create_test_rider.sh
```

### Option 3: Manual API Call
```bash
curl -X POST "https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/drivers/register" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test Rider",
    "email": "testrider@lesgo.com",
    "password": "TestRider123!",
    "password_confirmation": "TestRider123!",
    "phone_number": "+639171234567",
    "license_number": "N01-23-456789"
  }'
```

---

## Default Test Rider Account

### Credentials
- **Email:** `testrider@lesgo.com`
- **Password:** `TestRider123!`
- **Name:** Test Rider
- **Phone:** +639171234567
- **License Number:** N01-23-456789

### Status
- Initial status: `pending` (requires admin approval)
- After approval: `active` (can accept orders)

---

## Additional Test Accounts

You can create additional test riders by modifying the scripts or using different email addresses:

### Test Rider 2
```json
{
  "name": "Juan Dela Cruz",
  "email": "juan.rider@lesgo.com",
  "password": "JuanRider123!",
  "password_confirmation": "JuanRider123!",
  "phone_number": "+639171234568",
  "license_number": "N01-23-456790"
}
```

### Test Rider 3
```json
{
  "name": "Maria Santos",
  "email": "maria.rider@lesgo.com",
  "password": "MariaRider123!",
  "password_confirmation": "MariaRider123!",
  "phone_number": "+639171234569",
  "license_number": "N01-23-456791"
}
```

---

## API Endpoint

**POST** `/api/v1/drivers/register`

**Base URL:** `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1`

### Request Body
```json
{
  "name": "string (required)",
  "email": "string (required, unique)",
  "password": "string (required, min:8)",
  "password_confirmation": "string (required)",
  "phone_number": "string (required)",
  "license_number": "string (required)",
  "license_expiry_date": "date (optional)",
  "partner_id": "integer (optional)"
}
```

### Response (201 Created)
```json
{
  "success": true,
  "message": "Driver registered successfully",
  "data": {
    "user": {
      "id": 1,
      "name": "Test Rider",
      "email": "testrider@lesgo.com",
      "phone_number": "+639171234567",
      "role": "driver",
      "created_at": "2026-04-17T10:00:00.000000Z",
      "updated_at": "2026-04-17T10:00:00.000000Z"
    },
    "driver_profile": {
      "id": 1,
      "user_id": 1,
      "status": "pending",
      "rating": 0.0,
      "total_trips": 0,
      "license_number": "N01-23-456789",
      "license_expiry_date": null,
      "created_at": "2026-04-17T10:00:00.000000Z",
      "updated_at": "2026-04-17T10:00:00.000000Z"
    }
  }
}
```

---

## Login After Registration

After creating a rider account, you can login using:

**POST** `/api/v1/auth/login`

```json
{
  "email": "testrider@lesgo.com",
  "password": "TestRider123!",
  "device_name": "mobile-app"
}
```

### Response
```json
{
  "success": true,
  "message": "Login successful",
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Test Rider",
    "email": "testrider@lesgo.com",
    "phone_number": "+639171234567",
    "role": "driver",
    "driver_profile": {
      "id": 1,
      "status": "pending",
      "rating": 0.0,
      "total_trips": 0
    }
  }
}
```

---

## Approving Rider Accounts (Admin Only)

To approve a rider account, an admin needs to update the driver profile status:

**PATCH** `/api/v1/drivers/{driver_id}`

```json
{
  "status": "active"
}
```

---

## Testing Checklist

- [ ] Create rider account using script
- [ ] Login with rider credentials
- [ ] Verify auto-login on app restart
- [ ] Test wallet operations (top-up, withdraw, history)
- [ ] Test order acceptance (requires admin approval first)
- [ ] Test location updates
- [ ] Test order status updates

---

## Notes

1. **Pending Status:** Newly registered riders have `pending` status and cannot accept orders until approved by admin.

2. **Wallet Balance:** Riders need a minimum wallet balance (default: ₱100) to accept orders. This is a security deposit.

3. **Document Verification:** In production, riders would need to upload documents (license, OR/CR, etc.) for verification.

4. **Rate Limiting:** The registration endpoint has rate limiting (3 requests per minute in production, 60 in local).

5. **Email Verification:** Email verification is optional but recommended for production.

---

## Troubleshooting

### "Email already exists"
- Use a different email address
- Or delete the existing account from the database

### "Invalid credentials" on login
- Double-check the email and password
- Ensure password meets minimum requirements (8 characters)

### "Insufficient wallet balance"
- Top up the wallet using the wallet screen
- Or have an admin credit the wallet directly

### "Order already accepted"
- The order was accepted by another driver
- Try accepting a different order

---

## Security Notes

⚠️ **These are test accounts for development only!**

- Do not use these credentials in production
- Change passwords regularly
- Use strong, unique passwords for production accounts
- Enable two-factor authentication in production
