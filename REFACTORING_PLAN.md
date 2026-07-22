# LESGO Codebase Refactoring Plan

## Phase 1 — Analysis Report

### Codebase Scale
| Metric | Backend (Laravel) | Frontend (Flutter) |
|--------|:-:|:-:|
| Total files | 261 PHP | 659 Dart |
| Total LOC | 39,708 | 88,434 |
| Models / Entities | 66 | — |
| Controllers / Screens | 58 | ~50 |
| Services | 45 | 29 |
| Middleware | 21 | — |
| Tests | 18 files | 6 files |
| Migrations | 65 | — |

---

### 🔴 CRITICAL FINDINGS

#### C1. Dead Middleware (10 files, ~2000 LOC)
**Files never registered or referenced anywhere:**
- `AdvancedAuditLogging.php`
- `AdvancedRateLimiting.php`
- `ApiRateLimitHeaders.php`
- `ApiVersioning.php`
- `CheckWalletBalance.php`
- `DeviceFingerprinting.php`
- `IpAccessControl.php`
- `StructuredLogging.php`
- `TrackAnalyticsEvents.php`
- `VerifyRequestSignature.php`

**Risk:** Zero — dead code, just wasting repository space.

#### C2. Dead Services (3 files, ~1500 LOC)
- `BusinessMetricsService.php` (0 references)
- `CdnService.php` (0 references)
- `GeofencingService.php` (0 references outside its own controller which is feature-flagged)

#### C3. Dead Frontend Files (10 files, ~1500 LOC)
- `lib/main_working.dart` (334 lines)
- `lib/main_minimal.dart` (456 lines)
- `lib/main_address_demo.dart` (39 lines)
- `lib/simple_address_demo.dart`
- `lib/test_medium_priority_api.dart`
- `lib/test_missions_api.dart`
- `lib/presentation/provider/main/booking/leseat/leseat_provider_old.dart`
- `lib/presentation/screens/demo/address_demo_screen.dart`
- `lib/presentation/widgets/payment/payment_method_selector_example.dart`
- `lib/presentation/widgets/address/address_selector_example.dart`

#### C4. Duplicate Order Status Constants (Frontend)
Two files defining the same thing:
- `lib/core/constants/order_status_constants.dart`
- `lib/core/constants/order_statuses.dart`

---

### 🟡 HIGH FINDINGS

#### H1. `fakerphp/faker` in production `require`
Should be in `require-dev`. Ships test dependency to production builds.

#### H2. env() used directly in Services (Laravel anti-pattern)
Files using `env()` outside config:
- `DatabaseReadReplicaService.php` (3 uses)
- `MediaStorageService.php` (2 uses)
- `VerifyRequestSignature.php` (1 use)

After `config:cache`, `env()` returns `null`. This will cause production failures.

#### H3. 3 Duplicate Payment Controllers
- `PaymentController.php` — CRUD + webhooks
- `PaymentGatewayController.php` — createInvoice, getInvoice, expireInvoice, refund
- `PaymentGatewayInvoicesController.php` — createInvoice, getInvoice, refund + wallet logic

`PaymentGatewayController` and `PaymentGatewayInvoicesController` have overlapping `createInvoice` and `getInvoice` methods.

#### H4. God Controllers (>500 lines)
| Controller | Lines | Concern |
|-----------|-------|---------|
| OrderController | 1042 | Should split: CRUD, status, tracking |
| AuthController | 837 | Should split: login/register, profile, account |
| LiveTrackingController | 687 | Acceptable for real-time |
| WalletController | 652 | Could split: balance, top-up, withdrawal |

#### H5. 5 Order Tracking Screens (Frontend duplication)
- `lesgo_order_tracking_screen.dart` (1051 lines)
- `lesbuy_order_tracking_screen.dart` (992 lines)
- `leseat_order_tracking_screen.dart` (978 lines)
- `simple_order_tracking_screen.dart` (873 lines)
- `live_tracking_screen.dart` (661 lines)

These likely share 60-70% of their code.

#### H6. Unused Models
- `Plan` (0 references)
- `CustomerProfile` (1 reference, likely just migration)
- `LesbuyItem` (1 reference)

---

### 🟠 MEDIUM FINDINGS

#### M1. Duplicate PaymentGateway services
- `PaymentGatewayService.php` — Xendit-only operations
- `PaymentGatewayManager.php` — Facade wrapping PayMongo + Xendit

Good pattern but `PaymentGatewayService` naming is confusing vs `PaymentGatewayManager`.

#### M2. Routes file too large (620 lines)
Should split into route groups: `routes/api/auth.php`, `routes/api/orders.php`, etc.

#### M3. Incomplete Repository Pattern (Frontend)
Only 5 repository interfaces exist for 29 data sources. Most providers call datasources directly.

#### M4. Manual DI registrations bypassing injectable
`injection.dart` has 25+ manual `isRegistered` guards instead of using `@injectable` annotations.

#### M5. No index on frequently queried columns
Wallet transactions queried by `wallet_id` + `type` + `created_at` but no composite index found.

#### M6. Inconsistent API error responses
Some controllers return `$this->error(msg, code)`, others throw exceptions. The exception handler catches them but error format varies.

---

### 🟢 LOW FINDINGS

#### L1. `audit_logs` table recreated shortly after enhancement
- `2026_02_28_110000_create_audit_logs_table.php`
- `2026_04_12_120000_enhance_audit_logs_table.php`
- `2026_04_12_130000_recreate_audit_logs_table.php`

Not a bug (migrations are additive) but messy history.

#### L2. Multiple deployment configs
Render, Vercel, Laravel Cloud, Docker, Procfile — pick one.

#### L3. Inconsistent naming
- Backend: `OrderWalletPaymentService` vs `WalletWithdrawalService` (some use "Order" prefix, some don't)
- Frontend: `leseat_provider_old.dart` should not exist

#### L4. camera dependency in dev_dependencies
`camera: ^0.11.0+1` in dev_dependencies but likely needed in production for document upload.

---

## Phase 2 — Prioritized Roadmap

### CRITICAL (Do first, zero risk)

| # | Task | Difficulty | Risk | Files | Benefit |
|---|------|:---:|:---:|:---:|---------|
| 1 | Delete dead middleware | Easy | None | 10 | -2000 LOC, cleaner codebase |
| 2 | Delete dead frontend files | Easy | None | 10 | -1500 LOC, no confusion |
| 3 | Delete dead services | Easy | None | 3 | -1500 LOC |
| 4 | Remove duplicate OrderStatuses constant | Easy | Low | 2 | Single source of truth |

### HIGH (Do next, low risk)

| # | Task | Difficulty | Risk | Files | Benefit |
|---|------|:---:|:---:|:---:|---------|
| 5 | Move `fakerphp` to require-dev | Easy | None | 1 | Smaller prod build |
| 6 | Fix env() usage in services | Easy | Low | 3 | Prevent production failures |
| 7 | Remove unused models | Easy | None | 3 | Less confusion |
| 8 | Merge duplicate payment controllers | Medium | Medium | 3-5 | Less duplication, clearer API |

### MEDIUM (Scheduled work)

| # | Task | Difficulty | Risk | Files | Benefit |
|---|------|:---:|:---:|:---:|---------|
| 9 | Split OrderController | Medium | Medium | 3 | Maintainability |
| 10 | Split routes into files | Easy | Low | 5 | Readability |
| 11 | Unify order tracking screens | Hard | High | 5 | -3000 LOC, consistency |
| 12 | Complete repository pattern | Hard | Medium | 30+ | Testability |
| 13 | Fix manual DI registrations | Medium | Medium | 2 | Proper code generation |

### LOW (When time permits)

| # | Task | Difficulty | Risk | Files | Benefit |
|---|------|:---:|:---:|:---:|---------|
| 14 | Consolidate deployment configs | Easy | None | 4 | Less confusion |
| 15 | Add composite DB indexes | Easy | Low | 1 | Performance |
| 16 | Rename inconsistent services | Easy | Low | 5 | Readability |
| 17 | Squash migration history | Hard | High | 65 | Cleaner DB setup |

---

## Phase 3 — Safe Refactoring (Starting Now)

### Task 1: Delete Dead Middleware
