# Merchant Withdrawal Feature - Implementation Plan

## 📋 Overview

This feature allows Merchants to withdraw their available earnings from their wallet to their chosen payout method (GCash, Maya, Bank Transfer).

## 🔍 Current Infrastructure Analysis

### Existing Tables:
1. **`wallets`** - User wallet balances
   - `user_id`, `balance`, `currency`
2. **`wallet_transactions`** - Transaction history
   - `wallet_id`, `type`, `amount`, `balance_before`, `balance_after`, `description`
3. **`wallet_top_ups`** - Top-up requests
   - `user_id`, `wallet_id`, `amount`, `status`, `payment_method`
4. **`partners`** - Merchant/restaurant data
   - `user_id`, `name`, `address`, etc.

### Existing Models:
- ✅ `Wallet.php`
- ✅ `WalletTransaction.php`
- ✅ `WalletTopUp.php`
- ✅ `Partner.php`

### What's Missing:
- ❌ Withdrawal request table
- ❌ Withdrawal API endpoints
- ❌ Withdrawal UI in mobile app
- ❌ Admin withdrawal management

## 🎯 Implementation Steps

### PHASE 1: Backend - Database & Models

#### 1.1 Create Migration: `merchant_withdrawal_requests` table
```php
Schema::create('merchant_withdrawal_requests', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
    $table->foreignId('partner_id')->nullable()->constrained()->nullOnDelete();
    
    $table->decimal('amount', 12, 2);
    $table->decimal('fee', 12, 2)->default(0);
    $table->decimal('net_amount', 12, 2); // amount - fee
    $table->string('currency', 3)->default('PHP');
    
    $table->enum('status', [
        'pending',
        'processing',
        'completed',
        'rejected',
        'failed'
    ])->default('pending');
    
    $table->string('payout_method'); // 'gcash', 'maya', 'bank_transfer'
    $table->string('payout_account_name');
    $table->string('payout_account_number');
    $table->string('payout_bank_name')->nullable(); // For bank transfers
    
    $table->string('reference_number')->unique()->nullable();
    $table->string('external_transaction_id')->nullable();
    
    $table->text('rejection_reason')->nullable();
    $table->text('admin_notes')->nullable();
    
    $table->foreignId('processed_by')->nullable()->constrained('users')->nullOnDelete();
    $table->timestamp('processed_at')->nullable();
    $table->timestamp('completed_at')->nullable();
    
    $table->timestamps();
    
    $table->index(['user_id', 'status']);
    $table->index(['partner_id', 'status']);
    $table->index('status');
});
```

#### 1.2 Create Model: `MerchantWithdrawalRequest.php`
- Relationships: user, wallet, partner, processedBy
- Scopes: pending(), processing(), completed(), rejected()
- Accessors: statusLabel, payoutMethodLabel
- Methods: approve(), reject(), complete(), cancel()

#### 1.3 Update `Wallet` Model
Add method:
```php
public function availableBalance()
{
    // Balance minus pending withdrawals
    $pendingWithdrawals = MerchantWithdrawalRequest::where('wallet_id', $this->id)
        ->whereIn('status', ['pending', 'processing'])
        ->sum('amount');
    
    return $this->balance - $pendingWithdrawals;
}
```

### PHASE 2: Backend - API Endpoints

#### 2.1 Routes (`routes/api.php`)
```php
// Merchant Withdrawal Routes
Route::middleware(['auth:sanctum'])->group(function () {
    Route::prefix('merchant/withdrawals')->group(function () {
        Route::get('/', [MerchantWithdrawalController::class, 'index']);
        Route::post('/', [MerchantWithdrawalController::class, 'store']);
        Route::get('/{withdrawal}', [MerchantWithdrawalController::class, 'show']);
        Route::post('/{withdrawal}/cancel', [MerchantWithdrawalController::class, 'cancel']);
        Route::get('/summary', [MerchantWithdrawalController::class, 'summary']);
    });
});

// Admin Withdrawal Management Routes
Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::prefix('admin/withdrawals')->group(function () {
        Route::get('/', [AdminWithdrawalController::class, 'index']);
        Route::post('/{withdrawal}/approve', [AdminWithdrawalController::class, 'approve']);
        Route::post('/{withdrawal}/reject', [AdminWithdrawalController::class, 'reject']);
        Route::post('/{withdrawal}/complete', [AdminWithdrawalController::class, 'complete']);
    });
});
```

#### 2.2 Controller: `MerchantWithdrawalController.php`

**`index()` - List withdrawals**
- Query user's withdrawals
- Paginate results
- Return: id, amount, status, payout_method, created_at

**`store()` - Create withdrawal request**
- Validate:
  - Amount > 0
  - Amount <= available balance
  - Payout method is valid
  - Payout account details provided
- Lock balance (mark as pending)
- Create withdrawal request record
- Create wallet transaction (type: 'withdrawal_reserved')
- Send notification to admin
- Return: withdrawal request details

**`show()` - Get withdrawal details**
- Return full withdrawal details

**`cancel()` - Cancel pending withdrawal**
- Only allow if status = 'pending'
- Release locked balance
- Update status to 'cancelled'
- Create reversal transaction

**`summary()` - Get withdrawal summary**
- Total withdrawn (completed)
- Pending withdrawals
- Available balance
- Total earnings

#### 2.3 Validation Rules
```php
'amount' => 'required|numeric|min:100|max:available_balance',
'payout_method' => 'required|in:gcash,maya,bank_transfer',
'payout_account_name' => 'required|string|max:255',
'payout_account_number' => 'required|string|max:50',
'payout_bank_name' => 'required_if:payout_method,bank_transfer',
```

### PHASE 3: Mobile App - Data Layer

#### 3.1 API Constants
```dart
// lib/core/constants/api_constants.dart
static const String merchantWithdrawals = '/v1/merchant/withdrawals';
static const String merchantWithdrawalsSummary = '/v1/merchant/withdrawals/summary';
```

#### 3.2 DTOs
```dart
// lib/data/data_source/dto/merchant/withdrawal_request_dto.dart
class MerchantWithdrawalRequestDto {
  final int id;
  final double amount;
  final double fee;
  final double netAmount;
  final String status;
  final String payoutMethod;
  final String payoutAccountName;
  final String payoutAccountNumber;
  final String? referenceNumber;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  // statusLabel, payoutMethodLabel helpers
}

// lib/data/data_source/dto/merchant/withdrawal_summary_dto.dart
class MerchantWithdrawalSummaryDto {
  final double totalEarnings;
  final double availableBalance;
  final double pendingWithdrawals;
  final double totalWithdrawn;
}

// lib/data/data_source/dto/merchant/create_withdrawal_request_dto.dart
class CreateWithdrawalRequestDto {
  final double amount;
  final String payoutMethod;
  final String payoutAccountName;
  final String payoutAccountNumber;
  final String? payoutBankName;
}
```

#### 3.3 Remote Data Source
```dart
// lib/data/data_source/merchant_withdrawal_remote_datasource.dart
class MerchantWithdrawalRemoteDataSource {
  final DioClient _dioClient;
  
  Future<List<MerchantWithdrawalRequestDto>> getWithdrawals();
  Future<MerchantWithdrawalSummaryDto> getSummary();
  Future<MerchantWithdrawalRequestDto> createWithdrawal(CreateWithdrawalRequestDto request);
  Future<void> cancelWithdrawal(int withdrawalId);
}
```

### PHASE 4: Mobile App - State Management

#### 4.1 Provider
```dart
// lib/presentation/provider/main/merchantside/merchant_withdrawal_provider.dart
class MerchantWithdrawalState {
  final List<MerchantWithdrawalRequestDto> withdrawals;
  final MerchantWithdrawalSummaryDto? summary;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
}

class MerchantWithdrawalNotifier extends StateNotifier<MerchantWithdrawalState> {
  Future<void> loadWithdrawals();
  Future<void> loadSummary();
  Future<bool> requestWithdrawal(CreateWithdrawalRequestDto request);
  Future<bool> cancelWithdrawal(int withdrawalId);
}
```

### PHASE 5: Mobile App - UI Screens

#### 5.1 Merchant Wallet Screen (Enhanced)
**File**: `lib/presentation/screens/main/merchantside/merchant_wallet_screen.dart`

**Layout**:
```
┌─────────────────────────────┐
│ Merchant Wallet             │
├─────────────────────────────┤
│ Total Earnings              │
│   ₱12,450.00               │
│                             │
│ Available Balance           │
│   ₱8,200.00                │
│                             │
│ Pending Withdrawals         │
│   ₱2,000.00                │
│                             │
│ ┌─────────────────────────┐│
│ │  💸 Withdraw Funds      ││
│ └─────────────────────────┘│
│                             │
│ Recent Withdrawals          │
│ ┌─────────────────────────┐│
│ │ ₱2,000 - GCash          ││
│ │ Completed - Jan 15      ││
│ └─────────────────────────┘│
└─────────────────────────────┘
```

**Features**:
- Display balances
- "Withdraw" button
- Recent withdrawal history
- Pull to refresh

#### 5.2 Withdrawal Request Screen
**File**: `lib/presentation/screens/main/merchantside/merchant_withdrawal_request_screen.dart`

**Form Fields**:
- Amount input (with max = available balance)
- Payout method dropdown (GCash, Maya, Bank Transfer)
- Account name input
- Account number input
- Bank name input (if bank transfer selected)
- Fee display (if applicable)
- Net amount display
- Submit button

**Validation**:
- Amount must be >= ₱100
- Amount must be <= available balance
- All fields required
- Account number format validation

#### 5.3 Withdrawal History Screen
**File**: `lib/presentation/screens/main/merchantside/merchant_withdrawal_history_screen.dart`

**List Items**:
- Amount
- Status badge (Pending/Processing/Completed/Rejected)
- Payout method
- Date
- Reference number
- Tap to view details

#### 5.4 Withdrawal Detail Screen
**File**: `lib/presentation/screens/main/merchantside/merchant_withdrawal_detail_screen.dart`

**Information**:
- Withdrawal ID
- Amount
- Fee
- Net Amount
- Status
- Payout Method
- Account Details
- Reference Number
- Dates (created, processed, completed)
- Admin Notes (if any)
- Rejection Reason (if rejected)
- Cancel button (if pending)

### PHASE 6: Admin Panel Integration

#### 6.1 Withdrawal Management Page
**Location**: `Lesgo-Admin-Panel/resources/views/admin/withdrawals/`

**Features**:
- List all withdrawal requests
- Filter by status, merchant, date range
- Sort by date, amount
- Bulk actions
- Search

**Actions**:
- Approve withdrawal
- Reject withdrawal (with reason)
- Mark as completed (with reference number)
- View merchant details
- View transaction history

#### 6.2 Admin Controller
```php
// app/Http/Controllers/Admin/WithdrawalController.php
class WithdrawalController extends Controller {
    public function index();           // List withdrawals
    public function show($id);         // View details
    public function approve($id);      // Approve request
    public function reject(Request $request, $id); // Reject with reason
    public function complete(Request $request, $id); // Mark completed
}
```

### PHASE 7: Security & Validation

#### 7.1 Backend Validation
```php
// Verify user is merchant
if (!auth()->user()->partner) {
    throw new UnauthorizedException('Only merchants can withdraw funds');
}

// Verify sufficient balance
$availableBalance = $wallet->availableBalance();
if ($request->amount > $availableBalance) {
    throw new ValidationException('Insufficient available balance');
}

// Prevent duplicate requests
$existingPending = MerchantWithdrawalRequest::where('user_id', auth()->id())
    ->where('status', 'pending')
    ->where('amount', $request->amount)
    ->where('created_at', '>', now()->subMinutes(5))
    ->exists();

if ($existingPending) {
    throw new ValidationException('Duplicate withdrawal request detected');
}

// Lock balance
DB::transaction(function() use ($request, $wallet) {
    // Create withdrawal request
    // Create wallet transaction (withdrawal_reserved)
    // Update balance
});
```

#### 7.2 Middleware
```php
// Ensure only merchants can access
Route::middleware(['auth:sanctum', 'merchant'])->group(function () {
    // Withdrawal routes
});
```

### PHASE 8: Testing

#### 8.1 Backend Tests
- ✅ Merchant can create withdrawal request
- ✅ Merchant cannot withdraw more than available balance
- ✅ Merchant cannot withdraw ₱0 or negative amount
- ✅ Balance is locked during pending withdrawal
- ✅ Multiple pending withdrawals correctly lock balance
- ✅ Admin can approve withdrawal
- ✅ Admin can reject withdrawal
- ✅ Admin can mark as completed
- ✅ Rejected withdrawal releases locked balance
- ✅ Non-merchants cannot access withdrawal endpoints
- ✅ Cannot create duplicate requests

#### 8.2 Mobile Tests
- ✅ Withdrawal screen displays correct balances
- ✅ Cannot submit invalid amount
- ✅ Cannot submit without payout details
- ✅ Success message on successful withdrawal request
- ✅ Error message on failure
- ✅ Withdrawal appears in history immediately
- ✅ Can view withdrawal details
- ✅ Can cancel pending withdrawal
- ✅ Balance updates correctly after request

## 📊 Database Schema Summary

```sql
-- merchant_withdrawal_requests table
CREATE TABLE merchant_withdrawal_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    wallet_id BIGINT NOT NULL,
    partner_id BIGINT NULL,
    amount DECIMAL(12,2) NOT NULL,
    fee DECIMAL(12,2) DEFAULT 0,
    net_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'PHP',
    status ENUM('pending','processing','completed','rejected','failed') DEFAULT 'pending',
    payout_method VARCHAR(50) NOT NULL,
    payout_account_name VARCHAR(255) NOT NULL,
    payout_account_number VARCHAR(50) NOT NULL,
    payout_bank_name VARCHAR(255) NULL,
    reference_number VARCHAR(100) UNIQUE NULL,
    external_transaction_id VARCHAR(255) NULL,
    rejection_reason TEXT NULL,
    admin_notes TEXT NULL,
    processed_by BIGINT NULL,
    processed_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (partner_id) REFERENCES partners(id) ON DELETE SET NULL,
    FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_status (user_id, status),
    INDEX idx_partner_status (partner_id, status),
    INDEX idx_status (status)
);
```

## 🔄 Workflow

### User Flow:
1. Merchant opens Wallet screen
2. Sees available balance
3. Taps "Withdraw"
4. Enters amount and payout details
5. Submits request
6. Balance is locked (pending)
7. Admin approves/rejects
8. If approved → money sent → status = completed
9. If rejected → balance unlocked

### Admin Flow:
1. Admin opens Withdrawals page
2. Sees list of pending requests
3. Clicks on request to view details
4. Reviews merchant info, amount, payout details
5. Approves or rejects
6. If approved → processes payment externally
7. Marks as completed with reference number
8. Merchant sees completed withdrawal

## 📝 Notes

- Minimum withdrawal: ₱100
- Withdrawal fee: ₱0 (can be configured later)
- Payout methods: GCash, Maya, Bank Transfer
- Processing time: 1-3 business days
- Balance locking prevents double-spending
- Admin approval required for all withdrawals
- Rejected withdrawals release locked balance

## ⚠️ Important Considerations

1. **Balance Accuracy**: Always calculate available balance server-side
2. **Transaction Atomicity**: Use DB transactions for withdrawal requests
3. **Audit Trail**: Log all withdrawal actions
4. **Notifications**: Notify merchant on status changes
5. **Fraud Prevention**: Implement rate limiting and duplicate detection
6. **Compliance**: Follow financial regulations
7. **Error Handling**: Graceful failures with proper error messages

---

**Ready for Implementation?** This plan covers all requirements including backend API, mobile UI, admin management, security, and testing.
