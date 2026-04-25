# 🎉 Seeded Data Summary

## ✅ Successfully Seeded!

### 📊 Statistics:
- **Restaurants**: 3
- **Stores**: 3
- **Total Menu Items/Products**: 20
- **Menu Categories**: 11

---

## 🍕 LesEat Restaurants

### 1. Jollibee - Claveria
**Category**: Restaurant (Fast Food)
- **Location**: Station 2, Barangay Balabag, Boracay
- **Rating**: 4.7 ⭐ (1,250 reviews)
- **Delivery Fee**: ₱49.00
- **Min Order**: ₱150
- **Delivery Time**: 30 minutes
- **Status**: ✅ Featured

**Menu Items**:
- **Chickenjoy**:
  - 1-pc Chickenjoy - ₱85.00 (Popular)
  - 2-pc Chickenjoy - ₱165.00 (Popular)
- **Burgers**:
  - Yumburger - ₱45.00 (Popular)
  - Champ - ₱125.00

---

### 2. McDonald's - Boracay
**Category**: Restaurant (Fast Food)
- **Location**: Station 1, Barangay Balabag, Boracay
- **Rating**: 4.6 ⭐ (980 reviews)
- **Delivery Fee**: ₱49.00
- **Min Order**: ₱150
- **Delivery Time**: 35 minutes
- **Status**: Active

**Menu Items**:
- **Meals**:
  - Big Mac Meal - ₱185.00 (Popular, Featured)
  - Quarter Pounder Meal - ₱195.00 (Popular)
  - 6-pc Chicken McNuggets Meal - ₱165.00

---

### 3. Bella Italia Pizzeria
**Category**: Restaurant (Italian)
- **Location**: Station 3, Barangay Balabag, Boracay
- **Rating**: 4.8 ⭐ (450 reviews)
- **Delivery Fee**: ₱59.00
- **Min Order**: ₱200
- **Delivery Time**: 40 minutes
- **Status**: ✅ Featured

**Menu Items**:
- **Pizza**:
  - Margherita Pizza - ₱350.00 (Popular, Featured)
  - Pepperoni Pizza - ₱395.00 (Popular)
- **Pasta**:
  - Spaghetti Carbonara - ₱285.00 (Popular)

---

## 🛒 LesBuy Stores

### 1. 7-Eleven - Boracay Station 2
**Category**: Grocery (Convenience Store)
- **Location**: Station 2, Main Road, Boracay
- **Rating**: 4.5 ⭐ (320 reviews)
- **Delivery Fee**: ₱39.00
- **Min Order**: ₱100
- **Delivery Time**: 20 minutes
- **Status**: ✅ Featured

**Products**:
- **Snacks**:
  - Piattos Cheese - ₱35.00/pack (Popular)
  - Nova Multigrain - ₱28.00/pack
- **Drinks**:
  - Coca-Cola 1.5L - ₱65.00/bottle (Popular)
  - C2 Green Tea - ₱25.00/bottle (Popular)

---

### 2. Mercury Drug - Boracay
**Category**: Pharmacy
- **Location**: D-Mall, Station 2, Boracay
- **Rating**: 4.7 ⭐ (580 reviews)
- **Delivery Fee**: ₱49.00
- **Min Order**: ₱150
- **Delivery Time**: 30 minutes
- **Status**: Active

**Products**:
- **Medicine**:
  - Biogesic 500mg - ₱7.50/tablet (Popular)
  - Neozep Forte - ₱8.50/tablet (Popular)
- **Vitamins**:
  - Vitamin C 500mg - ₱5.00/tablet (Popular)

---

### 3. Alfamart - Boracay
**Category**: Grocery
- **Location**: Station 3, Boracay Island
- **Rating**: 4.4 ⭐ (290 reviews)
- **Delivery Fee**: ₱39.00
- **Min Order**: ₱100
- **Delivery Time**: 25 minutes
- **Status**: Active

**Products**:
- **Groceries**:
  - Lucky Me Pancit Canton - ₱15.00/pack (Popular)
  - Spam Classic 340g - ₱185.00/can
  - Alaska Evaporated Milk - ₱45.00/can

---

## 🎯 How to Test

### LesEat (Restaurants):
1. Open Customer App: http://localhost:8081
2. Login with: `testcustomer@lesgo.com` / `password`
3. Go to "LesEat" section
4. You should see:
   - ✅ Jollibee (Featured)
   - ✅ McDonald's
   - ✅ Bella Italia (Featured)
5. Click any restaurant to see menu items
6. Add items to cart and create order

### LesBuy (Stores):
1. Open Customer App: http://localhost:8081
2. Login with: `testcustomer@lesgo.com` / `password`
3. Go to "LesBuy" section
4. You should see:
   - ✅ 7-Eleven (Featured)
   - ✅ Mercury Drug
   - ✅ Alfamart
5. Click any store to see products
6. Add items to cart and create order

---

## 📝 Database Tables Populated

### `partners` table:
- 6 partners total (3 restaurants + 3 stores)
- All with complete information
- Featured flags set
- Ratings and reviews

### `menu_categories` table:
- 11 categories total
- Organized by partner
- Active status set

### `menu_items` table:
- 20 items total
- Prices set
- Popular items marked
- Featured items marked
- Stock availability set

---

## 🔧 Seeder File Location

**File**: `BACKEND/lesgo-api/database/seeders/PartnerMenuSeeder.php`

**To Re-run**:
```bash
cd BACKEND/lesgo-api
php artisan db:seed --class=PartnerMenuSeeder
```

**To Clear and Re-seed**:
```bash
# Delete existing data first
php artisan tinker --execute="Partner::whereIn('category', ['restaurant', 'grocery', 'pharmacy'])->delete();"

# Then re-seed
php artisan db:seed --class=PartnerMenuSeeder
```

---

## ✨ Features Included

### Restaurants:
- ✅ Multiple cuisines (Filipino, American, Italian)
- ✅ Fast food and fine dining options
- ✅ Popular items marked
- ✅ Featured restaurants
- ✅ Realistic pricing
- ✅ Menu categories

### Stores:
- ✅ Convenience stores (7-Eleven, Alfamart)
- ✅ Pharmacy (Mercury Drug)
- ✅ Various product categories
- ✅ Realistic pricing
- ✅ Unit specifications (pack, bottle, tablet, can)
- ✅ Popular products marked

---

## 🎊 Ready for Testing!

All data is now live in the database and ready to be displayed in the apps!

**Next Steps**:
1. ✅ Open Customer App
2. ✅ Browse LesEat restaurants
3. ✅ Browse LesBuy stores
4. ✅ Add items to cart
5. ✅ Create orders
6. ✅ Test driver assignment

---

**Seeded**: April 22, 2026
**Total Items**: 20 menu items/products
**Total Partners**: 6 (3 restaurants + 3 stores)
