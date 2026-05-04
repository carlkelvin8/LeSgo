# 🏪 Merchant Login Credentials

## ✅ Test Merchant Account Ready!

### 📱 Login Details:

**Email:** `merchant@test.com`  
**Password:** `password123`  
**Role:** Partner (Merchant)

---

## 🎯 How to Access Merchant Side:

### In the RIDERSIDE App:

1. **Open the app** (currently building on emulator)
2. On **Welcome Screen**, tap **"Login"**
3. Select **"Merchant Login"** (middle option)
4. Enter credentials:
   - Email: `merchant@test.com`
   - Password: `password123`
5. Tap **"Login"**

---

## 🏪 Merchant Profile:

- **Business Name:** Test Restaurant
- **Legal Name:** Test Restaurant Inc.
- **Category:** Restaurant
- **Cuisine:** Filipino, Asian
- **Status:** Active ✅
- **Featured:** Yes ⭐
- **Rating:** 4.5/5.0
- **Delivery Fee:** ₱30.00
- **Min Order:** ₱100
- **Est. Delivery:** 30 minutes

---

## 📋 Merchant Features Available:

### 1. **Orders View**
- View incoming orders
- Accept/reject orders
- Update order status
- Track order progress

### 2. **Menu Management**
- Add/edit menu categories
- Add/edit menu items
- Set prices and descriptions
- Upload food images
- Manage availability

### 3. **Profile**
- View business information
- Edit restaurant details
- Update operating hours
- Manage contact info

### 4. **Book View**
- Browse available services
- View menu items
- Test ordering flow

### 5. **Mission View**
- View daily missions/tasks
- Track performance
- View earnings

---

## 🔧 Backend API Endpoints:

All merchant endpoints are available at: `http://127.0.0.1:8000/api/v1/`

**Key Endpoints:**
- `POST /auth/login` - Login
- `GET /partners` - Get partner list
- `GET /partners/{id}` - Get partner details
- `GET /partners/{id}/menu` - Get menu
- `POST /menu-categories` - Add category
- `POST /menu-items` - Add menu item
- `GET /orders` - Get orders

---

## 📝 Notes:

- ✅ Backend is running on port 8000
- ✅ Emulator is booting
- ✅ RIDERSIDE app is building
- ✅ Merchant account is active

---

## 🚀 Next Steps:

1. Wait for app to finish building
2. Login with merchant credentials
3. Explore merchant dashboard
4. Add menu items
5. Test order management

---

## 🆘 Troubleshooting:

**Can't login?**
- Check backend is running: http://127.0.0.1:8000
- Verify credentials are correct
- Check network connection in emulator

**App not showing merchant option?**
- Make sure you're on the Login screen
- Look for 3 login options (Customer, Merchant, Rider)

**Need to reset password?**
- Run: `php create_test_merchant.php` again
- Or manually update in database

---

**Ready to test!** 🎉
