# Quick Test Guide - Merchant Menu API Integration

## ✅ What Was Fixed
The "Add Item" button now **actually saves to the database** instead of just showing a fake success message!

## 🚀 How to Test Right Now

### Step 1: Login (if not already logged in)
- Email: `merchant@test.com`
- Password: `password123`

### Step 2: Go to Menu Tab
- Click on the "Book" or "Menu" tab in the bottom navigation

### Step 3: Add a New Menu Item
1. Click the **"+"** button (usually in the top right)
2. Fill in the form:
   - **Item Name**: "My Test Pizza"
   - **Price**: "299.00"
   - **Category**: Select any category (e.g., "Pizza")
   - **Description**: "This is a real item saved to database"
3. Click **"Add Item"**

### Step 4: Verify It Works
- ✅ You should see "Item added successfully" message
- ✅ The form should close
- ✅ **The new item should appear in your menu list immediately**
- ✅ The item is now saved in the database

### Step 5: Verify Database Persistence
1. Close the app completely (swipe it away from recent apps)
2. Reopen the app
3. Login again with merchant account
4. Go to Menu tab
5. **Your item should still be there!** 🎉

## 🔍 What to Look For

### ✅ Success Indicators
- Item appears in menu list after adding
- Item persists after app restart
- You can see the item in the backend database
- Console shows: `✅ Menu item created successfully`

### ❌ Error Indicators
- If you see "No partner ID found" - logout and login again
- If you see "Failed to save item" - check if backend is running
- If item doesn't appear - check console for error messages

## 🐛 Troubleshooting

### Problem: "No partner ID found"
**Solution**: Logout and login again to refresh your session

### Problem: Item doesn't save
**Solution**: 
1. Check if backend is running: `http://localhost:8000`
2. Check console for error messages
3. Make sure you're logged in with merchant account

### Problem: Item shows but disappears after restart
**Solution**: This shouldn't happen anymore! If it does, check backend logs

## 📝 Technical Details

### What Changed
- `merchant_menu_item_form_provider.dart` now calls real API:
  - `POST /api/v1/partners/{partnerId}/menu-items` for new items
  - `PATCH /api/v1/menu-items/{itemId}` for editing items
- Menu providers automatically refresh after save
- Proper error handling for API failures

### Backend Endpoints
- Create: `POST /api/v1/partners/11/menu-items`
- Update: `PATCH /api/v1/menu-items/{id}`
- Get Menu: `GET /api/v1/partners/11/menu`

### Test Data
- Partner ID: 11 (Test Restaurant)
- Existing categories: Pizza, Burgers, Pasta, Salads, Desserts, Beverages
- 16 existing test menu items

## 🎯 Next Test: Edit Item
1. Click on any existing menu item
2. Change the name or price
3. Click "Save Item"
4. Verify the changes appear immediately

## 📊 Check Backend Database
You can verify items are saved by checking the `menu_items` table:
```sql
SELECT * FROM menu_items WHERE partner_id = 11 ORDER BY id DESC LIMIT 5;
```

---

**Status**: ✅ Ready to test!
**App**: Running on emulator
**Backend**: Running on port 8000
**Account**: merchant@test.com / password123
