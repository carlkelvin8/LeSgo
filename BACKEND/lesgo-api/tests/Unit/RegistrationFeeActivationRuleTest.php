<?php

namespace Tests\Unit;

use App\Models\RegistrationFeePayment;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

class RegistrationFeeActivationRuleTest extends TestCase
{
    public static function activationMatrix(): array
    {
        $cases = [];
        foreach ([RegistrationFeePayment::TYPE_RIDER, RegistrationFeePayment::TYPE_MERCHANT] as $type) {
            foreach ([
                [RegistrationFeePayment::APP_PENDING, RegistrationFeePayment::PAYMENT_UNPAID, false],
                [RegistrationFeePayment::APP_PENDING, RegistrationFeePayment::PAYMENT_PAID, false],
                [RegistrationFeePayment::APP_PENDING, RegistrationFeePayment::PAYMENT_WAIVED, false],
                [RegistrationFeePayment::APP_APPROVED, RegistrationFeePayment::PAYMENT_UNPAID, false],
                [RegistrationFeePayment::APP_APPROVED, RegistrationFeePayment::PAYMENT_PAID, true],
                [RegistrationFeePayment::APP_APPROVED, RegistrationFeePayment::PAYMENT_WAIVED, true],
                [RegistrationFeePayment::APP_REJECTED, RegistrationFeePayment::PAYMENT_PAID, false],
                [RegistrationFeePayment::APP_REJECTED, RegistrationFeePayment::PAYMENT_WAIVED, false],
            ] as [$application, $fee, $expected]) {
                $cases["{$type}:{$application}:{$fee}"] = [$type, $application, $fee, $expected];
            }
        }
        return $cases;
    }

    #[DataProvider('activationMatrix')]
    public function test_activation_requires_approval_and_paid_or_waived_fee(
        string $type,
        string $application,
        string $fee,
        bool $expected
    ): void {
        $payment = new RegistrationFeePayment([
            'account_type' => $type,
            'application_status' => $application,
            'payment_status' => $fee,
        ]);

        self::assertSame($expected, $payment->shouldBeActive());
    }

    public function test_paid_and_waived_remain_distinct_audit_states(): void
    {
        $paid = new RegistrationFeePayment(['payment_status' => RegistrationFeePayment::PAYMENT_PAID]);
        $waived = new RegistrationFeePayment(['payment_status' => RegistrationFeePayment::PAYMENT_WAIVED]);

        self::assertTrue($paid->isPaid());
        self::assertFalse($paid->isWaived());
        self::assertTrue($waived->isWaived());
        self::assertFalse($waived->isPaid());
    }
}
