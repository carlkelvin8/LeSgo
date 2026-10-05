<?php

namespace App\Http\Middleware;

use App\Services\RegistrationFeeService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRegistrationActive
{
    public function handle(Request $request, Closure $next, string $feature = 'operational features'): Response
    {
        $user = $request->user();
        if (!$user) {
            return $next($request);
        }

        // Only enforce for rider/merchant; customers/admins bypass
        $accountType = RegistrationFeeService::accountTypeForUser($user);
        if (!$accountType && !$user->isPartnerStaff()) {
            return $next($request);
        }

        $status = RegistrationFeeService::getStatusForUser($user);
        if (!($status['can_access_operational_features'] ?? $status['is_active'] ?? false)) {
            return response()->json([
                'success' => false,
                'message' => $status['display_status'] ?? 'Account restricted – registration fee and approval required',
                'error_code' => 'REGISTRATION_NOT_ACTIVE',
                'data' => $status,
            ], 403);
        }

        return $next($request);
    }
}
