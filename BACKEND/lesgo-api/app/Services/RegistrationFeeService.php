<?php

namespace App\Services;

use App\Models\RegistrationFeePayment;
use App\Models\User;
use App\Models\DriverProfile;
use App\Models\Partner;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class RegistrationFeeService
{
    public const SETTING_RIDER_FEE = 'registration.fee.rider';
    public const SETTING_MERCHANT_FEE = 'registration.fee.merchant';
    public const SETTING_ENFORCE_FROM = 'registration.fee.enforce_from';

    // -------------------------------------------------------------------------
    // Config
    // -------------------------------------------------------------------------

    public static function getFeeForType(string $accountType): float
    {
        if ($accountType === RegistrationFeePayment::TYPE_RIDER) {
            return RiderCommissionService::getPackagePrice(RiderCommissionService::PACKAGE_BASIC);
        }

        return RegistrationFeePayment::PARTNER_ANNUAL_FEE;
    }

    public static function getEnforceFromDate(): ?string
    {
        return \App\Models\SecuritySetting::getValue(self::SETTING_ENFORCE_FROM, null);
    }

    // -------------------------------------------------------------------------
    // Grandfather check
    // -------------------------------------------------------------------------

    public static function isGrandfathered(User $user): bool
    {
        $enforceFrom = self::getEnforceFromDate();
        if (!$enforceFrom) {
            return false;
        }
        try {
            $enforce = \Carbon\Carbon::parse($enforceFrom)->startOfDay();
            $created = $user->created_at ? \Carbon\Carbon::parse($user->created_at) : now();
            return $created->lt($enforce);
        } catch (\Throwable $e) {
            return false;
        }
    }

    public static function accountTypeForUser(User $user): ?string
    {
        if ($user->isDriver()) {
            return RegistrationFeePayment::TYPE_RIDER;
        }
        // Older owner accounts use partner/merchant instead of partner_admin.
        // Only a linked merchant owner may start its registration checkout.
        if ($user->isPartnerAdmin()
            || (in_array($user->role, ['partner', 'merchant'], true) && $user->partner()->exists())) {
            return RegistrationFeePayment::TYPE_MERCHANT;
        }
        return null;
    }

    // -------------------------------------------------------------------------
    // Ensure record exists
    // -------------------------------------------------------------------------

    public static function ensurePaymentRecord(User $user, ?string $accountType = null, ?float $overrideAmount = null): RegistrationFeePayment
    {
        $accountType = $accountType ?? self::accountTypeForUser($user);
        if (!$accountType) {
            throw new \RuntimeException('User is not Rider nor Merchant');
        }

        return DB::transaction(function () use ($user, $accountType, $overrideAmount) {
            // Lock the owner even when no fee row exists yet, so concurrent
            // first requests cannot both insert or create remote checkouts.
            User::whereKey($user->id)->lockForUpdate()->firstOrFail();
            $existing = RegistrationFeePayment::where('user_id', $user->id)
                ->where('account_type', $accountType)
                ->lockForUpdate()
                ->first();

            if ($existing) {
                $existing->renewAnnualFeeIfDue();
                // Update amount if config changed and not yet paid
                if (!$existing->isFeeSatisfied()
                    && $existing->payment_status !== RegistrationFeePayment::PAYMENT_PENDING
                    && ($overrideAmount === null || $accountType === RegistrationFeePayment::TYPE_MERCHANT)) {
                    $currentFee = self::feeForUser($user, $accountType);
                    if ($accountType === RegistrationFeePayment::TYPE_RIDER && (float) $existing->amount !== $currentFee) {
                        $existing->update(['amount' => $currentFee]);
                    } elseif ($accountType === RegistrationFeePayment::TYPE_MERCHANT
                        && (float) $existing->amount !== $currentFee
                        && $existing->payment_status !== RegistrationFeePayment::PAYMENT_PENDING) {
                        $existing->update([
                            'amount' => $currentFee,
                            'paymongo_checkout_id' => null,
                            'checkout_url' => null,
                            'paymongo_reference' => 'reg-fee-'.$user->id.'-'.$accountType.'-'.Str::uuid(),
                        ]);
                    }
                }
                return $existing->fresh();
            }

            $amount = $accountType === RegistrationFeePayment::TYPE_MERCHANT
                ? RegistrationFeePayment::PARTNER_ANNUAL_FEE
                : ($overrideAmount ?? self::feeForUser($user, $accountType));
            // Existing approvals survive rollout, but never imply payment.
            $profileStatus = $accountType === RegistrationFeePayment::TYPE_RIDER
                ? $user->driverProfile?->status : $user->partner?->status;
            $applicationStatus = in_array($profileStatus, ['active', 'offline', 'approved'], true)
                ? RegistrationFeePayment::APP_APPROVED
                : (in_array($profileStatus, ['suspended', 'rejected'], true)
                    ? RegistrationFeePayment::APP_REJECTED : RegistrationFeePayment::APP_PENDING);

            return RegistrationFeePayment::create([
                'user_id' => $user->id,
                'account_type' => $accountType,
                'amount' => $amount,
                'currency' => 'PHP',
                'paymongo_reference' => 'reg-fee-' . $user->id . '-' . $accountType . '-' . Str::uuid(),
                'idempotency_key' => 'reg-fee-' . $user->id . '-' . $accountType,
                'payment_status' => RegistrationFeePayment::PAYMENT_UNPAID,
                'application_status' => $applicationStatus,
                'is_active' => false,
            ]);
        });
    }

    private static function feeForUser(User $user, string $accountType): float
    {
        if ($accountType === RegistrationFeePayment::TYPE_RIDER) {
            $tier = $user->driverProfile?->package_tier ?? RiderCommissionService::PACKAGE_BASIC;

            return RiderCommissionService::getPackagePrice($tier);
        }

        return self::getFeeForType($accountType);
    }

    // -------------------------------------------------------------------------
    // PayMongo checkout
    // -------------------------------------------------------------------------

    public static function createCheckout(User $user, ?string $accountType = null): array
    {
        $accountType = $accountType ?? self::accountTypeForUser($user);
        if (!$accountType) {
            throw new \RuntimeException('Only Rider and Merchant accounts require registration fee');
        }

        // Persist the idempotency reference before a remote request. A timeout
        // must not roll it back and generate a different reference on retry.
        $existing = self::ensurePaymentRecord($user, $accountType);
        if ($existing->paymongo_checkout_id
            && in_array($existing->payment_status, [RegistrationFeePayment::PAYMENT_FAILED, RegistrationFeePayment::PAYMENT_EXPIRED], true)) {
            // A failed payment attempt can leave the hosted checkout active.
            // Gateway uncertainty must not create another chargeable session.
            self::verifyPayment($user, $existing->paymongo_checkout_id);
        }
        DB::transaction(function () use ($user, $accountType) {
            $record = self::ensurePaymentRecord($user, $accountType);
            if (in_array($record->payment_status, [RegistrationFeePayment::PAYMENT_FAILED, RegistrationFeePayment::PAYMENT_EXPIRED], true)) {
                $record->update([
                    'paymongo_reference' => 'reg-fee-'.$user->id.'-'.$accountType.'-'.Str::uuid(),
                    'payment_status' => RegistrationFeePayment::PAYMENT_UNPAID,
                    'paymongo_checkout_id' => null,
                    'checkout_url' => null,
                ]);
            }
        });
        return DB::transaction(function () use ($user, $accountType) {
            $record = self::ensurePaymentRecord($user, $accountType);

            if ($record->isFeeSatisfied()) {
                throw new \RuntimeException($record->isWaived() ? 'Registration fee has been waived' : 'Registration fee already paid');
            }

            // Prevent duplicate pending checkout reuse idempotently
            if ($record->payment_status === RegistrationFeePayment::PAYMENT_PENDING && $record->checkout_url && $record->paymongo_checkout_id) {
                // Resume the existing session. A network failure must never mint a
                // second chargeable session. Verification resolves terminal status.
                return [
                    'payment' => $record->fresh(),
                    'checkout_url' => $record->checkout_url,
                    'checkout_id' => $record->paymongo_checkout_id,
                    'paymongo_reference' => $record->paymongo_reference,
                    'reused' => true,
                ];
            }

            $amount = (float) $record->amount;
            $reference = $record->paymongo_reference;
            $description = $accountType === RegistrationFeePayment::TYPE_RIDER
                ? 'LeSgo Rider Registration Fee'
                : 'LeSgo Partner Annual Registration Fee';

            $gateway = app(PaymentGatewayManager::class);

            $checkout = $gateway->createInvoice(
                $amount,
                $reference,
                $description,
                [
                    'success_redirect_url' => config('services.paymongo.success_url') . '?type=registration_fee&account_type=' . $accountType,
                    'failure_redirect_url' => config('services.paymongo.failure_url') . '?type=registration_fee&account_type=' . $accountType,
                    'customer_email' => $user->email,
                    'customer_name' => $user->name,
                    'payer_email' => $user->email,
                    'payer_name' => $user->name,
                    'metadata' => [
                        'purpose' => 'registration_fee',
                        'account_type' => $accountType,
                        'user_id' => (string) $user->id,
                    ],
                ],
                'paymongo'
            );

            $record->update([
                'paymongo_checkout_id' => $checkout['id'] ?? null,
                'checkout_url' => $checkout['invoice_url'] ?? $checkout['checkout_url'] ?? null,
                'payment_status' => RegistrationFeePayment::PAYMENT_PENDING,
                'failure_reason' => null,
                'metadata' => array_merge($record->metadata ?? [], [
                    'last_checkout' => $checkout,
                    'checkout_created_at' => now()->toIso8601String(),
                ]),
            ]);

            Log::info('Registration fee checkout created', [
                'user_id' => $user->id,
                'account_type' => $accountType,
                'checkout_id' => $checkout['id'] ?? null,
                'reference' => $reference,
            ]);

            return [
                'payment' => $record->fresh(),
                'checkout_url' => $record->checkout_url,
                'checkout_id' => $record->paymongo_checkout_id,
                'paymongo_reference' => $record->paymongo_reference,
                'reused' => false,
            ];
        });
    }

    public static function verifyPayment(User $user, ?string $checkoutId = null): RegistrationFeePayment
    {
        $accountType = self::accountTypeForUser($user);
        $record = self::ensurePaymentRecord($user, $accountType);

        $checkoutId = $checkoutId ?? $record->paymongo_checkout_id;
        if (!$checkoutId) {
            throw new \RuntimeException('No checkout found to verify');
        }
        if ($checkoutId !== $record->paymongo_checkout_id) {
            throw new \RuntimeException('Checkout does not belong to the current registration period');
        }

        $gateway = app(PaymentGatewayManager::class);
        $invoice = $gateway->getInvoice($checkoutId, 'paymongo');

        $status = strtoupper($invoice['payment_status'] ?? $invoice['status'] ?? '');
        $isPaid = in_array($status, ['PAID', 'SUCCEEDED', 'COMPLETED'], true);

        return DB::transaction(function () use ($record, $checkoutId, $isPaid, $invoice, $status) {
            $locked = RegistrationFeePayment::where('id', $record->id)->lockForUpdate()->first();
            if ($locked->paymongo_checkout_id !== $checkoutId) {
                throw new \RuntimeException('Registration checkout changed during verification');
            }
            if ($locked->isPaid() || $locked->isWaived()) {
                return $locked;
            }

            if ($isPaid) {
                $locked->update([
                    'payment_status' => RegistrationFeePayment::PAYMENT_PAID,
                    'payment_date' => now(),
                    'failure_reason' => null,
                    'metadata' => array_merge($locked->metadata ?? [], ['verify_invoice' => $invoice]),
                ]);
                self::tryActivate($locked->fresh());
            } else {
                $knownFailed = in_array($status, ['FAILED', 'EXPIRED', 'CANCELLED'], true);
                if ($knownFailed) {
                    $locked->update([
                        'payment_status' => $status === 'EXPIRED' ? RegistrationFeePayment::PAYMENT_EXPIRED : RegistrationFeePayment::PAYMENT_FAILED,
                        'failure_reason' => 'Payment verification: status ' . $status,
                        'metadata' => array_merge($locked->metadata ?? [], ['verify_invoice' => $invoice]),
                    ]);
                } else {
                    $locked->update(['payment_status' => RegistrationFeePayment::PAYMENT_PENDING]);
                }
            }

            return $locked->fresh();
        });
    }

    // -------------------------------------------------------------------------
    // Webhook handlers (idempotent)
    // -------------------------------------------------------------------------

    public static function handleWebhookSuccess(string $checkoutId, array $payload = []): ?RegistrationFeePayment
    {
        return DB::transaction(function () use ($checkoutId, $payload) {
            $record = RegistrationFeePayment::where('paymongo_checkout_id', $checkoutId)
                ->orWhere('paymongo_reference', $checkoutId)
                ->lockForUpdate()
                ->first();

            if (!$record) {
                $externalId = $payload['external_id'] ?? $payload['paymongo_reference'] ?? null;
                if ($externalId) {
                    $record = RegistrationFeePayment::where('paymongo_reference', $externalId)->lockForUpdate()->first();
                }
            }

            if (!$record) {
                // Try by reference extracted from metadata
                $ref = $payload['reference'] ?? $payload['id'] ?? null;
                if ($ref) {
                    $record = RegistrationFeePayment::where('paymongo_reference', $ref)->lockForUpdate()->first();
                }
            }

            if (!$record) {
                // payment.paid events carry the Payment id (pay_...), which we persist
                // from the checkout_session payload as metadata.paymongo_payment_ids.
                $paymentIds = $payload['payment_ids'] ?? [];
                if (is_array($paymentIds)) {
                    foreach ($paymentIds as $pid) {
                        if (!is_string($pid)) {
                            continue;
                        }
                        $record = RegistrationFeePayment::where('metadata->paymongo_payment_ids', 'like', '%' . $pid . '%')->lockForUpdate()->first();
                        if ($record) {
                            break;
                        }
                    }
                }
            }

            if (!$record) {
                Log::warning('Registration fee webhook: record not found', ['checkout_id' => $checkoutId, 'payload' => $payload]);
                return null;
            }

            if ($record->isPaid() || $record->isWaived()) {
                return $record; // idempotent
            }

            $metadata = array_merge($record->metadata ?? [], ['webhook_success' => $payload, 'webhook_confirmed_at' => now()->toIso8601String()]);
            if (!empty($payload['payment_ids']) && is_array($payload['payment_ids'])) {
                $metadata['paymongo_payment_ids'] = array_values(array_unique(array_merge(
                    $record->metadata['paymongo_payment_ids'] ?? [],
                    $payload['payment_ids']
                )));
            }

            $record->update([
                'payment_status' => RegistrationFeePayment::PAYMENT_PAID,
                'payment_date' => now(),
                'failure_reason' => null,
                'metadata' => $metadata,
            ]);

            self::tryActivate($record->fresh());

            Log::info('Registration fee webhook success applied', ['user_id' => $record->user_id, 'checkout_id' => $checkoutId]);

            return $record->fresh();
        });
    }

    public static function handleWebhookFailed(string $checkoutId, string $reason, array $payload = []): ?RegistrationFeePayment
    {
        return DB::transaction(function () use ($checkoutId, $reason, $payload) {
            $record = RegistrationFeePayment::where('paymongo_checkout_id', $checkoutId)
                ->orWhere('paymongo_reference', $checkoutId)
                ->lockForUpdate()
                ->first();

            if (!$record) {
                $externalId = $payload['external_id'] ?? null;
                if ($externalId) {
                    $record = RegistrationFeePayment::where('paymongo_reference', $externalId)->lockForUpdate()->first();
                }
            }

            if (!$record) {
                $paymentIds = $payload['payment_ids'] ?? [];
                if (is_array($paymentIds)) {
                    foreach ($paymentIds as $pid) {
                        if (!is_string($pid)) {
                            continue;
                        }
                        $record = RegistrationFeePayment::where('metadata->paymongo_payment_ids', 'like', '%' . $pid . '%')->lockForUpdate()->first();
                        if ($record) {
                            break;
                        }
                    }
                }
            }

            if (!$record) {
                Log::warning('Registration fee webhook failed: record not found', ['checkout_id' => $checkoutId]);
                return null;
            }

            if ($record->isPaid() || $record->isWaived()) {
                return $record; // do not overwrite a paid or waived resolution
            }

            $metadata = array_merge($record->metadata ?? [], ['webhook_failed' => $payload]);
            if (!empty($payload['payment_ids']) && is_array($payload['payment_ids'])) {
                $metadata['paymongo_payment_ids'] = array_values(array_unique(array_merge(
                    $record->metadata['paymongo_payment_ids'] ?? [],
                    $payload['payment_ids']
                )));
            }

            $isExpired = str_contains(strtoupper($reason), 'EXPIRED');
            $record->update([
                'payment_status' => $isExpired ? RegistrationFeePayment::PAYMENT_EXPIRED : RegistrationFeePayment::PAYMENT_FAILED,
                'failure_reason' => substr($reason, 0, 1000),
                'metadata' => $metadata,
            ]);

            // Ensure is_active stays false
            self::syncActivation($record->fresh());

            return $record->fresh();
        });
    }

    // -------------------------------------------------------------------------
    // Application approval
    // -------------------------------------------------------------------------

    public static function approveApplication(RegistrationFeePayment $payment, User $admin): RegistrationFeePayment
    {
        return DB::transaction(function () use ($payment, $admin) {
            $locked = RegistrationFeePayment::where('id', $payment->id)->lockForUpdate()->first();
            $locked->update([
                'application_status' => RegistrationFeePayment::APP_APPROVED,
                'approved_at' => now(),
                'approved_by' => $admin->id,
            ]);
            return self::tryActivate($locked->fresh());
        });
    }

    public static function rejectApplication(RegistrationFeePayment $payment, User $admin, ?string $reason = null): RegistrationFeePayment
    {
        return DB::transaction(function () use ($payment, $admin, $reason) {
            $locked = RegistrationFeePayment::where('id', $payment->id)->lockForUpdate()->first();
            $locked->update([
                'application_status' => RegistrationFeePayment::APP_REJECTED,
                'approved_at' => null,
                'approved_by' => $admin->id,
                'is_active' => false,
                'activated_at' => null,
                'failure_reason' => $reason,
            ]);
            // Force restrictive status on profile/partner
            self::syncActivation($locked->fresh(), true);
            return $locked->fresh();
        });
    }

    public static function waiveFee(RegistrationFeePayment $payment, User $admin, ?string $reason = null): RegistrationFeePayment
    {
        return DB::transaction(function () use ($payment, $admin, $reason) {
            $locked = RegistrationFeePayment::where('id', $payment->id)->lockForUpdate()->firstOrFail();
            $locked->renewAnnualFeeIfDue();

            if ($locked->isPaid()) {
                throw new \DomainException('A paid registration fee cannot be changed to waived.');
            }

            if (!$locked->isWaived()) {
                $locked->update([
                    'payment_status' => RegistrationFeePayment::PAYMENT_WAIVED,
                    'waived_at' => now(),
                    'waived_by' => $admin->id,
                    'waiver_reason' => $reason,
                    'failure_reason' => null,
                    'metadata' => array_merge($locked->metadata ?? [], [
                        'fee_resolution' => 'admin_waiver',
                        'waiver_audit' => [
                            'waived_at' => now()->toIso8601String(),
                            'waived_by' => $admin->id,
                            'reason' => $reason,
                        ],
                    ]),
                ]);
            }

            return self::syncActivation($locked->fresh());
        });
    }

    // -------------------------------------------------------------------------
    // The single activation rule: Approved + (Paid or Waived) = Active
    // -------------------------------------------------------------------------

    public static function tryActivate(RegistrationFeePayment $payment): RegistrationFeePayment
    {
        return self::syncActivation($payment);
    }

    private static function syncActivation(RegistrationFeePayment $payment, bool $forceRestricted = false): RegistrationFeePayment
    {
        $shouldBeActive = !$forceRestricted && $payment->shouldBeActive();

        $payment->update([
            'is_active' => $shouldBeActive,
            'activated_at' => $shouldBeActive ? ($payment->activated_at ?? now()) : null,
        ]);

        $user = $payment->user ?? User::find($payment->user_id);
        if (!$user) {
            return $payment->fresh();
        }

        // Sync Rider profile
        if ($payment->account_type === RegistrationFeePayment::TYPE_RIDER) {
            $profile = $user->driverProfile ?? DriverProfile::where('user_id', $user->id)->first();
            if ($profile) {
                // Never auto-bypass: if not both conditions, ensure not active
                if ($shouldBeActive) {
                    if ($profile->status !== 'active') {
                        $profile->update(['status' => 'active']);
                    }
                } else {
                    // If application rejected → suspended, if pending → pending, if unpaid+approved → pending (still restricted)
                    if ($payment->application_status === RegistrationFeePayment::APP_REJECTED) {
                        $profile->update(['status' => 'suspended']);
                    } elseif ($payment->application_status === RegistrationFeePayment::APP_APPROVED && !$payment->isFeeSatisfied()) {
                        // Approved but unpaid → still restricted (keep pending)
                        if ($profile->status === 'active') {
                            $profile->update(['status' => 'pending']);
                        }
                    } elseif ($payment->isFeeSatisfied() && $payment->application_status === RegistrationFeePayment::APP_PENDING) {
                        if ($profile->status === 'active') {
                            $profile->update(['status' => 'pending']);
                        }
                    } else {
                        // generic pending
                        if (!in_array($profile->status, ['pending', 'suspended'], true) && !$payment->is_active) {
                            $profile->update(['status' => 'pending']);
                        }
                    }
                }
            }
        }

        // Sync Merchant partner
        if ($payment->account_type === RegistrationFeePayment::TYPE_MERCHANT) {
            $partner = $user->partner ?? Partner::where('user_id', $user->id)->first();
            if ($partner) {
                if ($shouldBeActive) {
                    if ($partner->status !== 'active') {
                        $partner->update(['status' => 'active']);
                    }
                } else {
                    if ($payment->application_status === RegistrationFeePayment::APP_REJECTED) {
                        $partner->update(['status' => 'rejected']);
                    } elseif ($payment->application_status === RegistrationFeePayment::APP_APPROVED && !$payment->isFeeSatisfied()) {
                        // Keep pending/rejected-like until paid
                        if ($partner->status === 'active') {
                            $partner->update(['status' => 'pending']);
                        }
                    } elseif ($payment->isFeeSatisfied() && $payment->application_status === RegistrationFeePayment::APP_PENDING) {
                        if ($partner->status === 'active') {
                            $partner->update(['status' => 'pending']);
                        }
                    } else {
                        if ($payment->application_status === RegistrationFeePayment::APP_PENDING && $partner->status === 'active' && !$payment->is_active) {
                            $partner->update(['status' => 'pending']);
                        }
                    }
                    // Also ensure store is not open while restricted
                    if ($partner->is_open && !$shouldBeActive) {
                        // Do not force close aggressively? But spec says cannot activate store while restricted — we soft-close
                        // Keep is_open true would imply active; but we leave is_open as is and enforce via middleware instead
                    }
                }
            }
        }

        return $payment->fresh();
    }

    // -------------------------------------------------------------------------
    // Status & access checks
    // -------------------------------------------------------------------------

    public static function getStatusForUser(User $user): array
    {
        // Staff operate the merchant's account; they cannot bypass its fee.
        if ($user->isPartnerStaff()) {
            $owner = $user->partnerStaff?->partner?->user;
            if (!$owner) {
                return ['requires_fee' => true, 'is_active' => false,
                    'can_access_app' => false, 'can_access_operational_features' => false,
                    'display_status' => 'Merchant account unavailable'];
            }
            return self::getStatusForUser($owner);
        }
        $accountType = self::accountTypeForUser($user);
        if (!$accountType) {
            return ['requires_fee' => false, 'is_active' => true, 'message' => 'No registration fee required'];
        }

        $record = self::ensurePaymentRecord($user, $accountType);

        $profileStatus = $accountType === RegistrationFeePayment::TYPE_RIDER
            ? $user->driverProfile()->value('status') : $user->partner()->value('status');
        $isActive = $record->shouldBeActive()
            && in_array($profileStatus, ['active', 'offline', 'approved'], true);
        $canOperational = $isActive;

        return [
            'requires_fee' => true,
            'payment_waived' => $record->isWaived(),
            'can_access_app' => $record->isFeeSatisfied(),
            'is_active' => $isActive,
            'can_access_operational_features' => $canOperational,
            'payment_status' => $record->payment_status,
            'application_status' => $record->application_status,
            'amount' => (float) $record->amount,
            'billing_period' => $accountType === RegistrationFeePayment::TYPE_MERCHANT ? 'annual' : 'one_time',
            'registration_expires_at' => $record->registration_expires_at?->toIso8601String(),
            'currency' => $record->currency,
            'paymongo_reference' => $record->paymongo_reference,
            'paymongo_checkout_id' => $record->paymongo_checkout_id,
            'checkout_url' => $record->checkout_url,
            'payment_date' => $record->payment_date?->toIso8601String(),
            'waived_at' => $record->waived_at?->toIso8601String(),
            'waived_by' => $record->waived_by,
            'waiver_reason' => $record->waiver_reason,
            'fee_resolution' => $record->isWaived() ? 'admin_waiver' : ($record->isPaid() ? 'paymongo_payment' : null),
            'approved_at' => $record->approved_at?->toIso8601String(),
            'approved_by' => $record->approved_by,
            'activated_at' => $record->activated_at?->toIso8601String(),
            'is_grandfathered' => (bool) $record->is_grandfathered,
            'display_status' => $record->displayCombinedStatus(),
            'account_status' => $record->displayAccountStatus(),
            'failure_reason' => $record->failure_reason,
        ];
    }

    public static function canAccessOperationalFeatures(User $user): bool
    {
        $status = self::getStatusForUser($user);
        // If user is not rider/merchant, always true
        if (!isset($status['requires_fee']) || $status['requires_fee'] === false) {
            return true;
        }
        return (bool) $status['is_active'];
    }

    public static function assertCanAccessOperationalFeatures(User $user, string $feature = 'operational features'): void
    {
        if (!self::canAccessOperationalFeatures($user)) {
            $status = self::getStatusForUser($user);
            $msg = $status['display_status'] ?? 'Account restricted – registration fee and approval required';
            throw new \RuntimeException($msg . ' — cannot access ' . $feature . '.');
        }
    }
}
