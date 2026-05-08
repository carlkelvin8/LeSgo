# 🧪 LEZGO Test Accounts

**Last Updated**: May 8, 2026  
**Environment**: Development/Testing

---

## 📱 CUSTOMER ACCOUNT

### **Login Credentials**:
```
Email: testcustomer@lesgo.com
Password: password
```

### **Account Details**:
- **Role**: Customer
- **Phone**: +639171234567
- **Email Verified**: Yes
- **Wallet**: Active with balance

### **Use For**:
- Testing customer app (FRONTEND)
- Booking orders (LesRide, LesEat, LesBuy)
- Testing payments
- Testing order tracking
- Testing chat with driver
- Testing reviews and ratings

---

## 🏍️ RIDER/DRIVER ACCOUNT

### **Login Credentials**:
```
Email: testrider@lesgo.com
Password: TestRider123!
```

### **Account Details**:
- **Role**: Driver
- **Phone**: +639171234567
- **Email Verified**: Yes
- **Driver Status**: Active/Approved
- **License Number**: ABC123456
- **Rating**: 4.5-5.0
- **Total Trips**: Multiple completed trips
- **Wallet**: Active with balance
- **Location**: Manila area (default)

### **Use For**:
- Testing rider app (RIDERSIDE)
- Accepting orders
- Testing navigation/tracking
- Testing order completion
- Testing earnings/wallet
- Testing driver missions
- Testing chat with customer

---

## 🏪 MERCHANT/PARTNER ACCOUNT

### **Login Credentials**:
```
Email: merchant@test.com
Password: password123
```

### **Account Details**:
- **Role**: Partner (Merchant)
- **Restaurant Name**: Test Restaurant
- **Phone**: +639171234567
- **Email Verified**: Yes
- **Partner Slug**: test-restaurant
- **Status**: Active/Approved
- **Has Menu Items**: Yes (test items added)
- **Has Categories**: Yes

### **Use For**:
- Testing merchant dashboard
- Managing menu items
- Managing orders
- Testing restaurant settings
- Testing partner analytics

---

## 🔐 ADMIN ACCOUNT (if needed)

### **Login Credentials**:
```
Email: admin@lesgo.com
Password: Admin123!
```

### **Account Details**:
- **Role**: Admin
- **Full Access**: Yes
- **Can Manage**: Users, Orders, Partners, Drivers, Settings

### **Use For**:
- Testing admin panel
- User management
- Order management
- Partner approval
- Driver verification
- System settings

---

## 🧪 ADDITIONAL TEST ACCOUNT

### **Carl's Account** (Developer):
```
Email: carlkelvinmanahan014@gmail.com
Password: [Your password]
```

### **Account Details**:
- **Role**: Customer/Admin (depending on setup)
- **Use For**: Personal testing and development

---

## 📝 QUICK REFERENCE

### **For Customer App Testing**:
```
Email: testcustomer@lesgo.com
Password: password
```

### **For Rider App Testing**:
```
Email: testrider@lesgo.com
Password: TestRider123!
```

### **For Merchant Testing**:
```
Email: merchant@test.com
Password: password123
```

---

## 🔧 VERIFICATION SCRIPTS

### **Verify All Test Accounts**:
```bash
cd BACKEND/lesgo-api
php verify_test_accounts.php
```

### **Verify Rider Account**:
```bash
cd BACKEND/lesgo-api
php verify_rider.php
```

### **Create Test Merchant** (if not exists):
```bash
cd BACKEND/lesgo-api
php create_test_merchant.php
```

### **Create Test User - Carl**:
```bash
cd BACKEND/lesgo-api
php create_test_user_carl.php
```

---

## 🧪 TEST SCENARIOS

### **Scenario 1: Complete Order Flow**
1. **Customer** (testcustomer@lesgo.com):
   - Login to FRONTEND app
   - Browse restaurants/stores
   - Add items to cart
   - Place order
   - Track order

2. **Driver** (testrider@lesgo.com):
   - Login to RIDERSIDE app
   - See pending order
   - Accept order
   - Navigate to pickup
   - Complete delivery

3. **Merchant** (merchant@test.com):
   - Login to merchant dashboard
   - See incoming order
   - Prepare order
   - Mark as ready

---

### **Scenario 2: Chat Testing**
1. **Customer** places order
2. **Driver** accepts order
3. Both can chat in real-time
4. Test message sending
5. Test read receipts
6. Test typing indicators

---

### **Scenario 3: Payment Testing**
1. **Customer** adds money to wallet
2. Place order with wallet payment
3. **Driver** completes order
4. Check wallet deduction (customer)
5. Check wallet credit (driver)
6. Check transaction history

---

### **Scenario 4: Rating & Review**
1. **Customer** completes order
2. Rate driver (1-5 stars)
3. Write review
4. **Driver** sees rating
5. Rating affects driver profile

---

## 🔒 SECURITY NOTES

### **Password Requirements**:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

### **Test Passwords**:
- `password` - Simple (for quick testing)
- `TestRider123!` - Strong (meets all requirements)
- `password123` - Medium (for merchant)

### **⚠️ IMPORTANT**:
- These are TEST accounts only
- DO NOT use in production
- Change passwords before production deployment
- Use strong passwords in production

---

## 📊 DATABASE QUERIES

### **Find Customer**:
```sql
SELECT * FROM users WHERE email = 'testcustomer@lesgo.com';
```

### **Find Rider with Profile**:
```sql
SELECT u.*, dp.* 
FROM users u 
LEFT JOIN driver_profiles dp ON u.id = dp.user_id 
WHERE u.email = 'testrider@lesgo.com';
```

### **Find Merchant with Partner**:
```sql
SELECT u.*, p.* 
FROM users u 
LEFT JOIN partners p ON u.id = p.user_id 
WHERE u.email = 'merchant@test.com';
```

### **Check Wallet Balance**:
```sql
SELECT u.email, w.balance, w.currency 
FROM users u 
LEFT JOIN wallets w ON u.id = w.user_id 
WHERE u.email IN ('testcustomer@lesgo.com', 'testrider@lesgo.com');
```

---

## 🚀 API TESTING

### **Login Test (Customer)**:
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testcustomer@lesgo.com",
    "password": "password",
    "device_name": "test-device"
  }'
```

### **Login Test (Rider)**:
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testrider@lesgo.com",
    "password": "TestRider123!",
    "device_name": "test-device"
  }'
```

### **Login Test (Merchant)**:
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "merchant@test.com",
    "password": "password123",
    "device_name": "test-device"
  }'
```

---

## 📱 MOBILE APP TESTING

### **FRONTEND (Customer App)**:
1. Open FRONTEND app
2. Tap "Login"
3. Enter: `testcustomer@lesgo.com` / `password`
4. Test all features

### **RIDERSIDE (Rider App)**:
1. Open RIDERSIDE app
2. Tap "Login"
3. Enter: `testrider@lesgo.com` / `TestRider123!`
4. Test all features

---

## 🔄 RESET TEST DATA

### **Reset Customer Orders**:
```sql
DELETE FROM orders WHERE user_id = (SELECT id FROM users WHERE email = 'testcustomer@lesgo.com');
```

### **Reset Driver Stats**:
```sql
UPDATE driver_profiles 
SET total_trips = 0, rating = 5.0 
WHERE user_id = (SELECT id FROM users WHERE email = 'testrider@lesgo.com');
```

### **Reset Wallet Balance**:
```sql
UPDATE wallets 
SET balance = 1000.00 
WHERE user_id IN (
  SELECT id FROM users 
  WHERE email IN ('testcustomer@lesgo.com', 'testrider@lesgo.com')
);
```

---

## 📞 SUPPORT

If test accounts are not working:

1. **Check Database**:
   ```bash
   php verify_test_accounts.php
   ```

2. **Recreate Accounts**:
   ```bash
   php create_test_merchant.php
   php create_test_user_carl.php
   ```

3. **Check Laravel Logs**:
   ```bash
   tail -f storage/logs/laravel.log
   ```

4. **Clear Cache**:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   ```

---

## ✅ CHECKLIST

Before testing, verify:
- [ ] Database is running
- [ ] Laravel server is running (php artisan serve)
- [ ] Test accounts exist (run verify script)
- [ ] Wallets are created
- [ ] Driver profile is approved
- [ ] Partner is active
- [ ] Menu items exist (for merchant)

---

**Happy Testing!** 🎉

For issues or questions, contact the development team.
