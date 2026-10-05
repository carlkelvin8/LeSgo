<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class VoucherService
{
    /**
     * Apply voucher to order and calculate discount (atomic with row lock)
     */
    public function applyVoucher(Order $order, string $voucherCode): array
    {
        $normalized = strtoupper(trim($voucherCode));
        return DB::transaction(function () use ($order, $normalized) {
            // Lock voucher row if DB-backed to serialize max_uses checks
            try {
                if (Schema::hasTable('vouchers')) {
                    $lock = Voucher::whereRaw('UPPER(code) = ?', [$normalized])->lockForUpdate()->first();
                    // if exists, validation will use locked state; if not, fallback still ok
                }
            } catch (\Throwable $e) {}

            // Also lock order row
            $lockedOrder = Order::lockForUpdate()->find($order->id);
            if (!$lockedOrder) {
                return ['valid' => false, 'error' => 'Order not found'];
            }

            $voucher = $this->validateVoucher($normalized, $lockedOrder);
            
            if (!$voucher['valid']) {
                return $voucher;
            }
            
            $discount = $this->calculateDiscount($lockedOrder, $voucher['voucher']);
            $newTotal = round(max(
                0,
                $this->resolveVoucherBaseAmount($lockedOrder) - $discount['amount']
            ), 2);
            $orderMeta = is_array($lockedOrder->meta) ? $lockedOrder->meta : [];
            $orderMeta['discount'] = $discount['amount'];
            $orderMeta['total'] = $newTotal;
            $orderMeta['grand_total'] = $newTotal;
            $orderMeta['voucher_details'] = $voucher['voucher'];
            $orderMeta['discount_breakdown'] = $discount;
            
            // Update order with voucher details (store normalized code)
            $lockedOrder->update([
                'voucher_code' => $normalized,
                'discount_amount' => $discount['amount'],
                'meta' => $orderMeta,
            ]);
            
            // Track voucher usage
            $this->trackVoucherUsage($normalized, $lockedOrder, $discount);
            
            return [
                'valid' => true,
                'discount_amount' => $discount['amount'],
                'discount_type' => $discount['type'],
                'new_total' => $newTotal,
                'voucher_details' => $voucher['voucher']
            ];
        });
    }
    
    /**
     * Validate voucher without applying it (for preview/validation only)
     */
    public function validateVoucherOnly(Order $order, string $voucherCode): array
    {
        $voucher = $this->validateVoucher($voucherCode, $order);
        
        if (!$voucher['valid']) {
            return $voucher;
        }
        
        $discount = $this->calculateDiscount($order, $voucher['voucher']);
        
        return [
            'valid' => true,
            'discount_amount' => $discount['amount'],
            'discount_type' => $discount['type'],
            'new_total' => max(0, $this->resolveVoucherBaseAmount($order) - $discount['amount']),
            'voucher_details' => $voucher['voucher']
        ];
    }
    
    /**
     * Validate voucher code and eligibility
     */
    private function validateVoucher(string $code, Order $order): array
    {
        $voucher = $this->getVoucherByCode($code);
        
        if (!$voucher) {
            return ['valid' => false, 'error' => 'Invalid voucher code'];
        }

        // Check active status (DB-backed)
        if (isset($voucher['is_active']) && !$voucher['is_active']) {
            return ['valid' => false, 'error' => 'Voucher is inactive'];
        }
        if (!$this->isVoucherActive($code)) {
            return ['valid' => false, 'error' => 'Voucher is inactive'];
        }
        
        // Check expiry - end of day in Manila timezone
        if (!empty($voucher['expires_at']) && Carbon::parse($voucher['expires_at'])->endOfDay()->isPast()) {
            return ['valid' => false, 'error' => 'Voucher has expired'];
        }
        
        // Check usage limits (case-insensitive, query actual DB usage)
        if (!empty($voucher['max_uses'])) {
            $actualUsageCount = Order::whereRaw('UPPER(voucher_code) = ?', [strtoupper($voucher['code'])])
                ->when($order->exists, fn ($query) => $query->where('id', '!=', $order->id))
                ->whereNotIn('status', ['cancelled', 'failed'])
                ->count();
            if ($actualUsageCount >= $voucher['max_uses']) {
                return ['valid' => false, 'error' => 'Voucher usage limit reached'];
            }
        }
        
        // Check user eligibility
        if (!$this->isUserEligible($order->customer_id, $voucher, $order->exists ? $order->id : null)) {
            return ['valid' => false, 'error' => 'You are not eligible for this voucher'];
        }
        
        // Check minimum order value
        if ($voucher['min_order_value'] && $this->resolveVoucherBaseAmount($order) < $voucher['min_order_value']) {
            return [
                'valid' => false, 
                'error' => "Minimum order value of ₱{$voucher['min_order_value']} required"
            ];
        }
        
        // Check service type eligibility (strict, cast to int)
        if (!empty($voucher['applicable_services'])) {
            $applicable = array_map('intval', (array) $voucher['applicable_services']);
            if (!in_array((int) $order->service_id, $applicable, true)) {
                return ['valid' => false, 'error' => 'Voucher not applicable to this service type'];
            }
        }
        
        return ['valid' => true, 'voucher' => $voucher];
    }
    
    /**
     * Calculate discount amount based on voucher type
     */
    private function calculateDiscount(Order $order, array $voucher): array
    {
        $baseAmount = $this->resolveVoucherBaseAmount($order);
        
        switch ($voucher['type']) {
            case 'percentage':
                $discountAmount = ($baseAmount * $voucher['value']) / 100;
                if ($voucher['max_discount']) {
                    $discountAmount = min($discountAmount, $voucher['max_discount']);
                }
                break;
                
            case 'fixed':
                $discountAmount = min($voucher['value'], $baseAmount);
                break;
                
            case 'free_delivery':
                // Calculate delivery fee portion
                $deliveryFee = $this->calculateDeliveryFee($order);
                $discountAmount = min($deliveryFee, $baseAmount);
                break;
                
            case 'buy_one_get_one':
                // For multiple items, discount the cheaper one
                $discountAmount = $this->calculateBOGODiscount($order);
                break;
                
            default:
                $discountAmount = 0;
        }
        
        return [
            'type' => $voucher['type'],
            'amount' => round(min(max(0, $discountAmount), $baseAmount), 2),
            'original_value' => $voucher['value'],
            'applied_to' => $baseAmount
        ];
    }

    private function resolveVoucherBaseAmount(Order $order): float
    {
        $meta = is_array($order->meta) ? $order->meta : [];
        if (isset($meta['subtotal'], $meta['delivery_fee'])
            && is_numeric($meta['subtotal'])
            && is_numeric($meta['delivery_fee'])) {
            return round(max(0, (float) $meta['subtotal']) + max(0, (float) $meta['delivery_fee']), 2);
        }

        return round(max(0, (float) ($order->estimated_fare ?? 0)), 2);
    }
    
    /**
     * Master voucher catalog (display + validation rules).
     * Now DB-driven with fallback to hardcoded definitions. Cached with withCount to avoid N+1.
     */
    private function allVoucherDefinitions(): array
    {
        // Try DB first - if vouchers table exists and has active records, use DB
        try {
            if (Schema::hasTable('vouchers')) {
                // Use cache to avoid per-request N+1
                $cacheKey = 'vouchers:active:definitions';
                $cached = Cache::get($cacheKey);
                if ($cached !== null && is_array($cached)) {
                    return $cached;
                }
                $dbVouchers = Voucher::where('is_active', true)->get();
                if ($dbVouchers->isNotEmpty()) {
                    $result = [];
                    foreach ($dbVouchers as $v) {
                        $result[strtoupper($v->code)] = array_merge($v->toVoucherArray(), [
                            'used_count' => Order::whereRaw('UPPER(voucher_code) = ?', [strtoupper($v->code)])->whereNotIn('status', ['cancelled','failed'])->count(),
                        ]);
                    }
                    Cache::put($cacheKey, $result, 60);
                    return $result;
                }
            }
        } catch (\Throwable $e) {
            Log::warning('Voucher DB fallback to hardcoded', ['error' => $e->getMessage()]);
        }

        // Fallback hardcoded definitions (used when DB empty or not migrated yet)
        return [
            'WELCOME10' => [
                'code' => 'WELCOME10',
                'title' => 'Welcome Discount',
                'description' => '10% off your first order',
                'discount_text' => '10% OFF',
                'min_order' => '₱100',
                'type' => 'percentage',
                'value' => 10,
                'max_discount' => 50,
                'min_order_value' => 100,
                'max_uses' => 1000,
                'used_count' => 150,
                'expires_at' => '2026-12-31',
                'user_restrictions' => ['new_users_only' => true],
                'applicable_services' => null,
            ],
            'SAVE20' => [
                'code' => 'SAVE20',
                'title' => 'Save Big',
                'description' => '₱20 off orders above ₱150',
                'discount_text' => '₱20 OFF',
                'min_order' => '₱150',
                'type' => 'fixed',
                'value' => 20,
                'max_discount' => null,
                'min_order_value' => 150,
                'max_uses' => 500,
                'used_count' => 89,
                'expires_at' => '2026-06-30',
                'user_restrictions' => [],
                'applicable_services' => null,
            ],
            'FREEDEL' => [
                'code' => 'FREEDEL',
                'title' => 'Free Delivery',
                'description' => 'Free delivery on orders above ₱200',
                'discount_text' => 'FREE DELIVERY',
                'min_order' => '₱200',
                'type' => 'free_delivery',
                'value' => 0,
                'max_discount' => null,
                'min_order_value' => 200,
                'max_uses' => null,
                'used_count' => 0,
                'expires_at' => null,
                'user_restrictions' => [],
                'applicable_services' => [1, 2],
            ],
            'RIDE20' => [
                'code' => 'RIDE20',
                'title' => 'Save on your next ride',
                'description' => 'Get 20% off LesRide bookings around Claveria, Cagayan.',
                'discount_text' => '20% OFF',
                'min_order' => '₱100',
                'type' => 'percentage',
                'value' => 20,
                'max_discount' => 80,
                'min_order_value' => 100,
                'max_uses' => null,
                'used_count' => 0,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => [2],
            ],
            'LUNCHFREE' => [
                'code' => 'LUNCHFREE',
                'title' => 'Free delivery for lunch',
                'description' => 'Order from partner restaurants and skip the delivery fee.',
                'discount_text' => 'FREE DELIVERY',
                'min_order' => '₱150',
                'type' => 'free_delivery',
                'value' => 0,
                'max_discount' => null,
                'min_order_value' => 150,
                'max_uses' => null,
                'used_count' => 0,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => [3],
            ],
            'PAYBACK' => [
                'code' => 'PAYBACK',
                'title' => 'LesPay cashback',
                'description' => 'Pay with LesPay wallet and receive cashback credit.',
                'discount_text' => 'P50 BACK',
                'min_order' => '₱200',
                'type' => 'fixed',
                'value' => 50,
                'max_discount' => null,
                'min_order_value' => 200,
                'max_uses' => null,
                'used_count' => 0,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => null,
            ],
        ];
    }

    /**
     * Get voucher details by code (DB first, then hardcoded)
     */
    private function getVoucherByCode(string $code): ?array
    {
        $normalized = strtoupper(trim($code));

        // Try DB direct lookup first for most up-to-date data (including inactive check via validation)
        try {
            if (Schema::hasTable('vouchers')) {
                $dbVoucher = Voucher::whereRaw('UPPER(code) = ?', [$normalized])->first();
                if ($dbVoucher) {
                    $arr = $dbVoucher->toVoucherArray();
                    $arr['used_count'] = Order::whereRaw('UPPER(voucher_code) = ?', [strtoupper($dbVoucher->code)])->whereNotIn('status', ['cancelled','failed'])->count();
                    return $arr;
                }
            }
        } catch (\Throwable $e) {
            Log::warning('Voucher DB lookup failed', ['error' => $e->getMessage()]);
        }

        $vouchers = $this->allVoucherDefinitions();
        return $vouchers[$normalized] ?? null;
    }

    /**
     * Check if voucher is active in DB (for DB-backed vouchers, inactive should be invalid)
     */
    private function isVoucherActive(string $code): bool
    {
        try {
            if (Schema::hasTable('vouchers')) {
                $exists = Voucher::whereRaw('UPPER(code) = ?', [strtoupper(trim($code))])->exists();
                if ($exists) {
                    return (bool) Voucher::whereRaw('UPPER(code) = ?', [strtoupper(trim($code))])->where('is_active', true)->exists();
                }
            }
        } catch (\Throwable $e) {}
        return true; // hardcoded vouchers are active by default
    }
    
    /**
     * Check if user is eligible for voucher
     */
    private function isUserEligible(int $userId, array $voucher, ?int $currentOrderId = null): bool
    {
        $restrictions = $voucher['user_restrictions'] ?? [];
        
        // Check if new users only - only count non-cancelled/failed orders
        if (isset($restrictions['new_users_only']) && $restrictions['new_users_only']) {
            $orderCount = Order::where('customer_id', $userId)
                ->when($currentOrderId !== null, fn ($query) => $query->where('id', '!=', $currentOrderId))
                ->whereNotIn('status', ['cancelled','failed'])
                ->count();
            
            if ($orderCount > 0) {
                return false; // Not a new user
            }
        }
        
        // Check usage per user limit
        if (isset($restrictions['max_uses_per_user'])) {
            $userUsageCount = $this->getUserVoucherUsageCount(
                $userId,
                $voucher['code'],
                $currentOrderId,
            );
            if ($userUsageCount >= $restrictions['max_uses_per_user']) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Calculate delivery fee portion of order
     */
    private function calculateDeliveryFee(Order $order): float
    {
        $meta = is_array($order->meta) ? $order->meta : [];
        if (isset($meta['delivery_fee']) && is_numeric($meta['delivery_fee'])) {
            return max(0, (float) $meta['delivery_fee']);
        }

        // Estimate delivery fee based on distance
        $distanceKm = $order->estimated_distance_m / 1000;
        return max(30, $distanceKm * 8); // Minimum ₱30, ₱8 per km
    }
    
    /**
     * Calculate BOGO discount
     */
    private function calculateBOGODiscount(Order $order): float
    {
        $meta = is_array($order->meta) ? $order->meta : [];
        $metaItems = $meta['items'] ?? null;
        if (is_array($metaItems)) {
            $unitPrices = [];
            $totalQuantity = 0;
            foreach ($metaItems as $item) {
                if (!is_array($item)) {
                    continue;
                }
                $price = $item['estimated_price'] ?? $item['price'] ?? null;
                $quantity = $item['quantity'] ?? 0;
                if (!is_numeric($price) || !is_numeric($quantity) || (int) $quantity < 1) {
                    continue;
                }
                $unitPrices[] = max(0, (float) $price);
                $totalQuantity += (int) $quantity;
            }
            return $totalQuantity >= 2 && $unitPrices !== [] ? min($unitPrices) : 0;
        }

        $items = $order->lesbuyItems;
        if ($items->sum('quantity') < 2) {
            return 0;
        }

        return (float) ($items->min('estimated_price') ?? 0);
    }
    
    /**
     * Track voucher usage
     */
    private function trackVoucherUsage(string $code, Order $order, array $discount): void
    {
        // In a real implementation, this would update voucher usage in database
        // and create usage tracking records
        
        Cache::increment("voucher_usage:{$code}");
        
        // Log voucher usage for analytics
        Log::info('Voucher applied', [
            'voucher_code' => $code,
            'order_id' => $order->id,
            'customer_id' => $order->customer_id,
            'discount_amount' => $discount['amount'],
            'original_fare' => $order->estimated_fare
        ]);
    }
    
    /**
     * Get user's voucher usage count (case-insensitive, exclude cancelled/failed)
     */
    private function getUserVoucherUsageCount(int $userId, string $code, ?int $currentOrderId = null): int
    {
        return Order::where('customer_id', $userId)
                   ->whereRaw('UPPER(voucher_code) = ?', [strtoupper(trim($code))])
                   ->when($currentOrderId !== null, fn ($query) => $query->where('id', '!=', $currentOrderId))
                   ->whereNotIn('status', ['cancelled','failed'])
                   ->count();
    }
    
    /**
     * Get available vouchers for user
     */
    public function getAvailableVouchers(User $user): array
    {
        $availableVouchers = [];

        foreach ($this->allVoucherDefinitions() as $code => $voucher) {
            $validation = $this->validateVoucherForUser($code, $user);
            $voucher['claimed'] = $this->isVoucherClaimed($user, $code);
            if ($validation['eligible']) {
                $voucher['eligible'] = true;
            } else {
                $voucher['eligible'] = false;
                $voucher['reason'] = $validation['reason'];
            }
            $availableVouchers[] = $voucher;
        }

        return $availableVouchers;
    }

    /**
     * Claim/save a voucher for the offers screen (validates eligibility first). Atomic via Cache::add.
     */
    public function claimVoucher(User $user, string $code): array
    {
        $normalized = strtoupper(trim($code));
        $validation = $this->validateVoucherForUser($normalized, $user);

        if (!$validation['eligible']) {
            return [
                'success' => false,
                'error'   => $validation['reason'] ?? 'Not eligible for this voucher',
            ];
        }

        $key = "user_claimed_voucher:{$user->id}:{$normalized}";
        // Atomic add - only succeeds if not already claimed
        $added = Cache::add($key, true, 60 * 60 * 24 * 30); // 30 days
        if (!$added && Cache::has($key)) {
            return [
                'success' => false,
                'error'   => 'Voucher already claimed',
            ];
        }
        // Ensure forever for backward compat if add succeeded
        if ($added) {
            Cache::put($key, true, 60 * 60 * 24 * 30);
        }

        return [
            'success' => true,
            'code'    => $normalized,
            'message' => 'Voucher claimed successfully',
        ];
    }

    public function isVoucherClaimed(User $user, string $code): bool
    {
        return Cache::has('user_claimed_voucher:' . $user->id . ':' . strtoupper(trim($code)));
    }
    
    /**
     * Validate voucher for user without order context
     */
    private function validateVoucherForUser(string $code, User $user): array
    {
        $voucher = $this->getVoucherByCode($code);
        
        if (!$voucher) {
            return ['eligible' => false, 'reason' => 'Invalid voucher'];
        }

        if (isset($voucher['is_active']) && !$voucher['is_active']) {
            return ['eligible' => false, 'reason' => 'Voucher inactive'];
        }
        if (!$this->isVoucherActive($code)) {
            return ['eligible' => false, 'reason' => 'Voucher inactive'];
        }
        
        // Check expiry - end of day
        if (!empty($voucher['expires_at']) && Carbon::parse($voucher['expires_at'])->endOfDay()->isPast()) {
            return ['eligible' => false, 'reason' => 'Expired'];
        }
        
        // Check user eligibility
        if (!$this->isUserEligible($user->id, $voucher)) {
            return ['eligible' => false, 'reason' => 'Not eligible'];
        }
        
        return ['eligible' => true];
    }
}
