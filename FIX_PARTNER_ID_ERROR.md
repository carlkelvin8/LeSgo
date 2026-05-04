# Fix "Partner ID not found" Error

## 🔴 Current Problem
You're seeing: **"Partner ID not found. Please login again."**

This happens because you're logged in with an **old session** that doesn't have the `partner_id` field.

## ✅ Simple Fix - Logout and Login Again

### Step 1: Logout
1. In the app, find the **Profile** or **Settings** section
2. Click **Logout** button
3. You should be taken back to the login screen

### Step 2: Login Again
1. Email: `merchant@test.com`
2. Password: `password123`
3. Click **Login**

### Step 3: Try Adding Item Again
1. Go to **Menu/Book** tab
2. Click **"+"** to add new item
3. Fill in the form
4. Click **"Add Item"**
5. ✅ **It should work now!**

## 🔍 Why This Happens
- The backend was updated to return `partner_id` in the login response
- Your current session was created **before** this update
- Logging out and logging in again will get you a **fresh session** with `partner_id`

## 📝 What the Logs Show
```
I/flutter: ⚠️ No partner ID found for menu
I/flutter: ⚠️ No partner ID found for menu items
```

After logout/login, you should see:
```
I/flutter: ✅ Loaded menu with X categories
I/flutter: ✅ Loaded X menu items
```

## 🚨 If Logout Button Not Found
If you can't find a logout button in the merchant side:

### Option 1: Clear App Data
1. Long press the app icon
2. Go to **App Info**
3. Click **Storage**
4. Click **Clear Data**
5. Reopen app and login

### Option 2: Reinstall App
1. Uninstall the app from emulator
2. The Flutter process will automatically reinstall it
3. Login again

---

**TL;DR**: Just logout and login again! 🔄
