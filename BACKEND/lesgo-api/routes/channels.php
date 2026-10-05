<?php

use App\Models\ChatConversation;
use App\Models\Geofence;
use App\Models\Order;
use Illuminate\Support\Facades\Broadcast;

// Wrap all channel registrations in try/catch to prevent build failures
// when broadcasting env vars (REVERB_APP_KEY etc.) are not yet available.
try {

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// driver.{driverId} consistently uses the driver's users.id.
Broadcast::channel('driver.{driverId}', function ($user, $driverId) {
    return $user->isDriver() && (int) $user->id === (int) $driverId;
});

Broadcast::channel('order.{orderId}', function ($user, $orderId) {
    $order = Order::find($orderId);

    if (! $order) {
        return false;
    }

    return (int) $user->id === (int) $order->customer_id
        || (int) $user->driverProfile?->id === (int) $order->driver_id
        || $user->isAdmin();
});

Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = ChatConversation::find($conversationId);

    if (! $conversation) {
        return false;
    }

    return (int) $user->id === (int) $conversation->customer_id
        || (int) $user->id === (int) $conversation->driver_id
        || $user->isAdmin();
});

Broadcast::channel('notifications.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

Broadcast::channel('geofence.{geofenceId}', function ($user, $geofenceId) {
    $geofence = Geofence::find($geofenceId);

    return $geofence
        && ((int) $user->id === (int) $geofence->created_by || $user->isAdmin());
});

Broadcast::channel('drivers.nearby', function ($user) {
    return $user->isDriver() && $user->driverProfile?->status === 'active';
});

Broadcast::channel('orders.customer.{customerId}', function ($user, $customerId) {
    return (int) $user->id === (int) $customerId;
});

Broadcast::channel('orders.driver.{driverProfileId}', function ($user, $driverProfileId) {
    return (int) $user->driverProfile?->id === (int) $driverProfileId;
});

Broadcast::channel('orders.partner.{partnerId}', function ($user, $partnerId) {
    return $user->isAdmin()
        || ($user->isPartnerAdmin() && (int) $user->partner?->id === (int) $partnerId);
});

Broadcast::channel('drivers.{driverProfileId}.location', function ($user, $driverProfileId) {
    if ($user->isAdmin() || (int) $user->driverProfile?->id === (int) $driverProfileId) {
        return true;
    }

    return Order::where('driver_id', $driverProfileId)
        ->where('customer_id', $user->id)
        ->whereIn('status', [
            'accepted',
            'driver_arrived_at_pickup',
            'in_progress',
            'picked_up',
            'ready_for_pickup',
        ])
        ->exists();
});

} catch (\Throwable $e) {
    // Broadcasting not available during build — silently skip
}
