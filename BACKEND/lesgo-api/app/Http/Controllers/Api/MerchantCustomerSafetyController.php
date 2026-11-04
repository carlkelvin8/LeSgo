<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatReport;
use App\Models\Order;
use App\Models\Partner;
use App\Services\MerchantCustomerSafetyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Report or block the customer of an order, from the merchant side.
 * App Store Guideline 1.2: content and users must be reportable and blockable.
 */
class MerchantCustomerSafetyController extends Controller
{
    public function __construct(private MerchantCustomerSafetyService $safety) {}

    /** GET /orders/{order}/customer-safety */
    public function show(Request $request, Order $order): JsonResponse
    {
        $partner = $this->safety->partnerFor($request->user(), $order);
        if (! $partner) {
            return $this->error('Forbidden', 403);
        }

        return $this->success([
            'customer_blocked' => $order->customer_id
                ? MerchantCustomerSafetyService::storeBlocksCustomer($partner, (int) $order->customer_id)
                : false,
        ]);
    }

    /** POST /orders/{order}/report-customer */
    public function report(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();
        $partner = $this->safety->partnerFor($user, $order);
        if (! $partner) {
            return $this->error('Forbidden', 403);
        }

        $validated = $request->validate([
            'reason' => 'required|string|in:'.implode(',', ChatReport::REASONS),
            'details' => 'nullable|string|max:1000',
            'block' => 'nullable|boolean',
        ]);

        if ($rejection = $this->cannotTarget($order, $partner, (int) $user->id)) {
            return $rejection;
        }

        $result = $this->safety->report(
            $user,
            $partner,
            $order,
            $validated['reason'],
            $validated['details'] ?? null,
            (bool) ($validated['block'] ?? false),
        );

        return $this->created([
            'report_id' => $result['report']->id,
            'ticket_number' => $result['ticket']->ticket_number,
            'customer_blocked' => $result['blocked'],
        ], 'Thanks for reporting. Our team will review this within 24 hours.');
    }

    /** POST /orders/{order}/block-customer */
    public function block(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();
        $partner = $this->safety->partnerFor($user, $order);
        if (! $partner) {
            return $this->error('Forbidden', 403);
        }
        if ($rejection = $this->cannotTarget($order, $partner, (int) $user->id)) {
            return $rejection;
        }

        $this->safety->block($partner, (int) $order->customer_id);

        return $this->success(['customer_blocked' => true], 'Customer blocked. They can no longer order from your store.');
    }

    /** DELETE /orders/{order}/block-customer */
    public function unblock(Request $request, Order $order): JsonResponse
    {
        $partner = $this->safety->partnerFor($request->user(), $order);
        if (! $partner) {
            return $this->error('Forbidden', 403);
        }

        if ($order->customer_id) {
            $this->safety->unblock($partner, (int) $order->customer_id);
        }

        return $this->success(['customer_blocked' => false], 'Customer unblocked.');
    }

    /**
     * An order with no customer, or one placed by the store's own account (the
     * owner's, or the account acting now), has nobody to report or block.
     */
    private function cannotTarget(Order $order, Partner $partner, int $actingUserId): ?JsonResponse
    {
        if (! $order->customer_id) {
            return $this->error('This order has no customer to report.', 422);
        }
        if (in_array((int) $order->customer_id, [$actingUserId, (int) $partner->user_id], true)) {
            return $this->error('You cannot report or block your own account.', 422);
        }

        return null;
    }
}
