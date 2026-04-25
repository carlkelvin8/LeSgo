# Test Accounts Setup

## ✅ Ready to Test!

### 📱 Customer Account
- **Email**: `testcustomer@lesgo.com`
- **Password**: `password`
- **User ID**: 923
- **Role**: customer

### 🏍️ Rider Account
- **Email**: `testrider@lesgo.com`
- **Password**: `password`
- **User ID**: 926
- **Driver Profile ID**: 74
- **Wallet Balance**: ₱1,000.00
- **Status**: active
- **Location**: Manila area (14.5995, 120.9842)

## 🚀 Running Services

1. **Backend API**: http://127.0.0.1:8000 ✅
2. **Customer App**: http://localhost:8081 ✅
3. **Rider App**: http://localhost:8080 ✅
4. **Queue Worker**: Running ✅

## 📝 How to Test

### Customer Side:
1. Open http://localhost:8081
2. Login with `testcustomer@lesgo.com` / `password`
3. Create a booking (LesRide, LesEat, or LesBuy)
4. Wait for driver assignment (automatic via queue)

### Rider Side:
1. Open http://localhost:8080
2. Login with `testrider@lesgo.com` / `password`
3. Turn ON DUTY
4. View available orders in Bookings tab
5. Accept orders manually or wait for auto-assignment

## 🔄 Auto-Assignment Process

When a customer creates an order:
1. Order status: `pending`
2. `AutoAssignDriverJob` dispatched to queue
3. System finds available drivers within 10km radius
4. Ranks drivers by:
   - Distance (40% weight)
   - Rating (30% weight)
   - Completion rate (20% weight)
   - Availability (10% weight)
5. Assigns best driver automatically
6. Order status changes to `accepted`
7. Customer sees real driver name from database

## 🛠️ Maintenance Scripts

### Create Test Rider
```bash
cd BACKEND/lesgo-api
php create_test_rider.php
```

### Verify Test Accounts
```bash
cd BACKEND/lesgo-api
php verify_test_accounts.php
```

### Clear Cache
```bash
cd BACKEND/lesgo-api
php artisan cache:clear
```

### Restart Queue Worker
```bash
# Stop current queue worker (Ctrl+C)
php artisan queue:work --tries=3
```

## 📊 Database Info

- **Database**: PostgreSQL (localhost)
- **Total Users**: 776
- **Test Customer**: ID 923
- **Test Rider**: ID 926, Driver Profile ID 74

## ⚠️ Important Notes

1. **Real Data**: The system now uses real driver data from the database
2. **Queue Required**: Auto-assignment requires queue worker to be running
3. **Location Updates**: Rider app updates location every 30 seconds
4. **Cache**: Orders are cached for 5 minutes, cleared on new order creation
5. **Wallet**: Driver needs minimum balance (currently ₱1,000.00)

## 🐛 Troubleshooting

### No driver assigned?
- Check if rider is logged in and ON DUTY
- Check if rider has sufficient wallet balance
- Check if rider location is within 10km of pickup
- Check queue worker is running: `php artisan queue:work`

### Orders not showing?
- Clear cache: `php artisan cache:clear`
- Refresh the page
- Check browser console for errors

### Login errors?
- Verify credentials are correct
- Check backend is running on port 8000
- Check browser console for API errors
