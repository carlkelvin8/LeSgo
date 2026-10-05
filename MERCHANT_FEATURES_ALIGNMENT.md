# Merchant Features Alignment - RIDERSIDE vs FRONTEND

**Date:** June 17, 2026  
**Status:** Feature Gap Analysis Complete  
**Priority:** CRITICAL - Missing core merchant functionality

---

## 📊 Executive Summary

The **RIDERSIDE** (merchant app) has comprehensive merchant management features that are **COMPLETELY MISSING** from **FRONTEND** (customer app). This creates a gap where merchants have limited visibility into their business when using the customer-facing app.

**Features to Implement: 14 major features across 5 categories**

---

## 🔴 CRITICAL MISSING FEATURES

### 1. **Analytics Dashboard** ❌ MISSING
**RIDERSIDE Implementation:**
- Advanced dashboard with revenue summary
- Order trend charts (hourly/daily/weekly/monthly)
- Peak hours analysis
- Customer analytics (new vs returning, lifetime value, top spenders)
- Category performance breakdown
- Cancellation rates, average order value

**Why Needed in FRONTEND:**
- Merchants need quick business insights when on the go
- Real-time revenue tracking
- Performance monitoring

**Estimated Lines of Code:** 500+ (provider + UI)
**Complexity:** HIGH

**Key Components to Port:**
```dart
// From RIDERSIDE
- MerchantAnalyticsSummary (data model)
- merchantAnalyticsSummaryProvider (Riverpod provider)
- MerchantAnalyticsScreen (UI)
- Chart rendering with fl_chart library
```

---

### 2. **Earnings & Payout Management** ❌ MISSING
**RIDERSIDE Implementation:**
- Detailed earnings tracking by period
- Breakdown of completed vs pending earnings
- Payout history with status
- Withdrawal method management
- Earnings by category/menu item

**Why Needed in FRONTEND:**
- Core merchant functionality
- Financial transparency
- Income verification

**Estimated Lines of Code:** 400+ (3 screens + providers)
**Complexity:** MEDIUM

**Key Components:**
```dart
// From RIDERSIDE
- MerchantEarningsScreen
- MerchantPayoutHistoryScreen
- merchant_earnings_provider.dart
- MerchantOrderAmountUtils (calculation logic)
```

---

### 3. **Menu Management** ❌ MISSING
**RIDERSIDE Implementation:**
- Browse menu with category organization
- Add new menu items with image upload
- Edit/delete menu items
- Stock/inventory tracking
- Availability toggling per item
- Pricing management
- Item options/variations

**Why Needed in FRONTEND:**
- Quick menu updates from phone
- Inventory management on the go
- Stock status changes

**Estimated Lines of Code:** 800+ (4 screens + providers + services)
**Complexity:** HIGH

**Key Components:**
```dart
// From RIDERSIDE
- MerchantMenuView
- MerchantMenuAddItemScreen
- MerchantMenuEditItemScreen
- MerchantMenuAddCategoryScreen
- merchant_menu_provider.dart
- merchant_menu_item_form_provider.dart
```

---

### 4. **Real-time Order Management** ⚠️ PARTIAL
**FRONTEND Current:** Customer-side order tracking only  
**RIDERSIDE Implementation:**
- Accept/Reject incoming orders
- Real-time order listing with filtering
- Mark orders ready for pickup
- Cancel orders with reason
- Order detail view with customer info
- Preparation timer integration

**Why Needed:**
- Merchants need to manage orders in FRONTEND when not in RIDERSIDE
- Cross-app consistency

**Estimated Lines of Code:** 400+
**Complexity:** MEDIUM

**Key Changes:**
```dart
// Adapt from RIDERSIDE
- MerchantOrdersView (add to FRONTEND)
- MerchantOrderDetailScreen (add to FRONTEND)
- Filters: Pending, For Pick Up, For Delivery, Completed
- Action handlers: Accept, Reject, Ready, Cancel
```

---

### 5. **Sound Alerts & Notifications** ❌ MISSING
**RIDERSIDE Implementation:**
- Customizable order notification sounds
- Multiple sound options: bell, chime, ping, notification
- Volume control slider (0-100%)
- Vibration toggle
- Sound preview/test functionality
- Persistent settings storage

**Why Needed:**
- Merchants need alerts in FRONTEND when switching apps
- Consistency with RIDERSIDE behavior
- Professional notification handling

**Estimated Lines of Code:** 250+ (service + UI)
**Complexity:** MEDIUM

**Key Components:**
```dart
// From RIDERSIDE
- OrderSoundAlertService (full service logic)
- merchant_sound_settings_provider.dart
- MerchantSoundAlertSettingsScreen (adapt to FRONTEND)
```

---

## 🟡 HIGH PRIORITY FEATURES

### 6. **Wallet & Payment Management** ⚠️ PARTIAL
**Current State:** Generic wallet, not merchant-focused  
**Needs:** Merchant-specific wallet features

**Missing Components:**
- Merchant-specific topup flow
- Transaction filtering (commissions vs payouts)
- Pending earnings visualization
- Withdrawal management for merchants

**Estimated Lines of Code:** 300+
**Complexity:** MEDIUM

---

### 7. **Sales Report Generation** ❌ MISSING
**RIDERSIDE Implementation:**
- CSV export with detailed transaction data
- PDF reports with branding
- Period-based filtering
- Email/Share functionality
- Includes: Orders, revenue, items, customer info

**Why Needed:** 
- Accounting and bookkeeping
- Tax documentation
- Business analysis

**Estimated Lines of Code:** 200+ (service + UI)
**Complexity:** LOW

**Key Components:**
```dart
// From RIDERSIDE
- SalesReportService (CSV/PDF generation)
- Adapt to FRONTEND workflow
```

---

### 8. **Business Profile Management** ⚠️ PARTIAL
**Current State:** Basic user profile  
**Needs:** Business-focused profile editing

**Missing:**
- Edit business name, description, hours
- Cuisine categories/tags
- Service area management
- Business documents/certificates

**Estimated Lines of Code:** 250+
**Complexity:** LOW-MEDIUM

---

### 9. **Printer Support** ❌ MISSING
**RIDERSIDE Implementation:**
- Bluetooth printer discovery
- Receipt printing for orders
- ESC/POS command formatting
- Print settings (font size, paper width)

**Why Needed:**
- Kitchen/counter printing capability
- Integration with POS systems
- Order efficiency

**Estimated Lines of Code:** 300+ (service + UI)
**Complexity:** MEDIUM-HIGH

**Key Components:**
```dart
// From RIDERSIDE
- PrinterService
- EscPosUtils
- PrinterSettingsScreen
```

---

### 10. **Staff Management** ❌ MISSING
**RIDERSIDE Implementation:**
- View/manage partner staff members
- Role assignment (admin, cook, cashier)
- Permission management
- Staff activity tracking

**Why Needed:**
- Multi-user support
- Role-based access control
- Team management from app

**Estimated Lines of Code:** 400+
**Complexity:** MEDIUM-HIGH

**Key Components:**
```dart
// From RIDERSIDE
- MerchantStaffScreen
- merchant_staff_provider.dart
- Backend: PartnerStaffController (already in API)
```

---

## 🟢 MEDIUM PRIORITY FEATURES

### 11. **Customer Analytics** ❌ MISSING
**RIDERSIDE Tracking:**
- New vs returning customers
- Top spenders by lifetime value
- Customer frequency analysis
- Repeat rate calculations

**Why Needed:**
- Business insights
- Marketing data
- Loyalty program planning

**Estimated Lines of Code:** 200+ (calculations + UI)
**Complexity:** MEDIUM

---

### 12. **Mission/Bonus Programs** ❌ MISSING
**RIDERSIDE Implementation:**
- View available missions/bonuses
- Claim rewards
- Bonus history tracking

**Why Needed:**
- Merchant engagement
- Incentive participation

**Estimated Lines of Code:** 250+
**Complexity:** LOW

---

### 13. **Review Management Dashboard** ⚠️ PARTIAL
**Current State:** No merchant review view  
**RIDERSIDE Has:**
- All customer reviews listing
- Rating distribution
- Average rating display
- Response capability (if implemented)

**Why Needed:**
- Reputation management
- Customer feedback tracking

**Estimated Lines of Code:** 200+
**Complexity:** LOW

---

### 14. **Inventory Control** ⚠️ PARTIAL
**RIDERSIDE Implementation:**
- Stock level tracking per item
- Auto-hide when out of stock
- Manual availability toggle
- Low stock warnings

**Why Needed:**
- Prevent overselling
- Menu accuracy
- Real-time availability

**Estimated Lines of Code:** 200+
**Complexity:** MEDIUM

---

## 📋 Implementation Roadmap

### **Phase 1 - CRITICAL (Sprint 1-2)**
**Priority:** Must-have for FRONTEND merchant functionality

| Feature | Effort | Dependencies | Timeline |
|---------|--------|--------------|----------|
| Order Management UI | 2 days | Backend ✅ | Week 1 |
| Analytics Dashboard | 3 days | Backend ✅ | Week 1-2 |
| Menu Management | 4 days | Image service, Backend ✅ | Week 2 |
| Earnings Tracking | 2 days | Backend ✅ | Week 2 |
| Sound Alerts | 1 day | just_audio library ✅ | Week 2 |

**Total Phase 1: 12 days**

---

### **Phase 2 - HIGH (Sprint 3-4)**
**Priority:** Important for merchant feature parity

| Feature | Effort | Dependencies | Timeline |
|---------|--------|--------------|----------|
| Wallet Management | 2 days | Current wallet refactor | Week 3 |
| Sales Reports | 1 day | pdf, share_plus libs ✅ | Week 3 |
| Business Profile | 1.5 days | Backend ✅ | Week 3 |
| Review Dashboard | 1 day | Backend ✅ | Week 4 |
| Inventory System | 1.5 days | Menu management ✅ | Week 4 |

**Total Phase 2: 7 days**

---

### **Phase 3 - MEDIUM (Sprint 5-6)**
**Priority:** Nice-to-have enhancements

| Feature | Effort | Dependencies | Timeline |
|---------|--------|--------------|----------|
| Printer Support | 2 days | flutter_bluetooth_printer | Week 5 |
| Staff Management | 2.5 days | Backend ✅ | Week 5-6 |
| Customer Analytics | 2 days | Analytics engine ✅ | Week 6 |
| Missions/Bonuses | 1 day | Backend API | Week 6 |

**Total Phase 3: 7.5 days**

---

## 🔧 Technical Architecture

### **State Management (Riverpod)**
```dart
// Providers to implement in FRONTEND
- merchantOrdersProvider (FutureProvider)
- selectedMerchantOrderFilterProvider (StateProvider)
- merchantAnalyticsSummaryProvider (Provider)
- merchantMenuProvider (FutureProvider)
- merchantEarningsSummaryProvider (Provider)
- merchantWalletProvider (StateNotifierProvider) - enhance existing
- merchantSoundSettingsProvider (StateProvider)
```

### **UI Structure**
```
FRONTEND/lib/presentation/screens/main/merchantside/ (NEW)
├── merchant_orders_management_screen.dart
├── merchant_analytics_dashboard_screen.dart
├── merchant_menu_management_screen.dart
├── merchant_earnings_screen.dart
├── merchant_wallet_screen.dart (enhance)
├── merchant_sound_settings_screen.dart
├── merchant_staff_screen.dart
└── merchant_profile_screen.dart

FRONTEND/lib/presentation/provider/main/merchantside/ (NEW)
├── merchant_orders_provider.dart
├── merchant_analytics_provider.dart
├── merchant_menu_provider.dart
├── merchant_earnings_provider.dart
├── merchant_sound_settings_provider.dart
└── merchant_staff_provider.dart

FRONTEND/lib/core/services/ (ENHANCED)
├── order_sound_alert_service.dart (port from RIDERSIDE)
├── sales_report_service.dart (port from RIDERSIDE)
└── printer_service.dart (port from RIDERSIDE)
```

### **Dependencies to Add**
```yaml
# Already in RIDERSIDE, add to FRONTEND
- fl_chart: ^0.62.0 (charts for analytics)
- just_audio: ^0.9.36 (sound alerts)
- printing: ^5.11.0 (PDF generation)
- share_plus: ^4.0.0 (report sharing)
- pdf: ^3.10.0 (PDF creation)
- flutter_bluetooth_printer: (optional for Phase 3)
```

---

## 🎯 Key Implementation Notes

### 1. **Merchant Context Management**
- Need to detect when user is accessing as merchant
- Route merchant features based on user role (isMerchant)
- Differentiate UI/UX from customer mode

### 2. **Data Flow**
```
Backend API (LESGO-API)
  ↓
MerchantRemoteDataSource (adapt for FRONTEND)
  ↓
Riverpod Providers (NEW)
  ↓
Screens & Widgets
```

### 3. **Real-time Updates**
- Auto-refresh mechanism (every 10-30 seconds)
- FCM push notifications for new orders
- Prep timer synchronization

### 4. **Performance Optimization**
- Cache analytics data with TTL
- Lazy load category details
- Pagination for large order lists
- Debounce filter updates

### 5. **Shared Services with RIDERSIDE**
- Reuse `OrderSoundAlertService` logic
- Adapt `MerchantOrderAmountUtils` calculation functions
- Share `SalesReportService` implementation
- Common notification handling

---

## 📊 Feature Comparison Matrix

| Feature | RIDERSIDE | FRONTEND | Gap | Priority |
|---------|-----------|----------|-----|----------|
| Order Management | ✅ Full | ❌ None | CRITICAL | P0 |
| Analytics Dashboard | ✅ Advanced | ❌ None | CRITICAL | P0 |
| Menu Management | ✅ Full CRUD | ❌ None | CRITICAL | P0 |
| Earnings Tracking | ✅ Detailed | ❌ None | CRITICAL | P0 |
| Sound Alerts | ✅ Customizable | ❌ None | HIGH | P1 |
| Wallet (Merchant) | ✅ Merchant-specific | ⚠️ Generic | HIGH | P1 |
| Sales Reports | ✅ CSV/PDF | ❌ None | HIGH | P1 |
| Business Profile | ✅ Full Edit | ⚠️ Partial | MEDIUM | P2 |
| Printer Support | ✅ Bluetooth | ❌ None | MEDIUM | P2 |
| Staff Management | ✅ Screen Ready | ❌ None | MEDIUM | P2 |
| Customer Analytics | ✅ Detailed | ❌ None | MEDIUM | P2 |
| Missions/Bonuses | ✅ Available | ❌ None | MEDIUM | P2 |
| Review Dashboard | ✅ Full View | ❌ None | LOW | P3 |
| Inventory Control | ✅ Full System | ⚠️ Basic | LOW | P3 |

---

## ✅ Implementation Checklist

### Phase 1 Preparation
- [ ] Create directory structure for merchant screens
- [ ] Create merchant providers directory
- [ ] Add new dependencies to pubspec.yaml
- [ ] Port sound alert service from RIDERSIDE
- [ ] Copy calculation utilities from RIDERSIDE

### Phase 1 Implementation
- [ ] Order Management screen & logic
- [ ] Analytics Dashboard screen & provider
- [ ] Menu Management screens (Add/Edit/Browse)
- [ ] Earnings screen & provider
- [ ] Sound settings integration

### Phase 2 Implementation
- [ ] Wallet enhancement for merchants
- [ ] Sales report service integration
- [ ] Business profile screen
- [ ] Review dashboard
- [ ] Inventory control system

### Phase 3 Implementation
- [ ] Printer service & settings
- [ ] Staff management screen
- [ ] Customer analytics enhancement
- [ ] Missions/bonuses features

---

## 🚀 Success Metrics

- ✅ All Phase 1 features working with 0 critical bugs
- ✅ Analytics calculations matching RIDERSIDE
- ✅ Merchant satisfaction: Feature parity with RIDERSIDE
- ✅ Performance: Analytics load < 2 seconds
- ✅ Test coverage: > 80% for new merchant features

---

**Status:** Ready for Planning  
**Next Step:** Create detailed feature specs for Phase 1  
**Owner:** Development Team

