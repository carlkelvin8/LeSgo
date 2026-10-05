<?php

require __DIR__ . '/BACKEND/lesgo-api/vendor/autoload.php';

$app = require_once __DIR__ . '/BACKEND/lesgo-api/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "=== TESTING RIDER ORDER ACCEPTANCE ===\n\n";

// Get the test driver
$driver = App\Models\User::where('email', 'driver@lesgo.test')->first();

if (!$driver) {
    echo "❌ Driver not found!\n";
    exit(1);
}

echo "Driver: {$driver->name} (ID: {$driver->id})\n";
echo "Email: {$driver->email}\n";

// Create a test token
$token = $driver->createToken('test-device')->plainTextToken;
echo "Token: {$token}\n\n";

// Get pending order
$order = App\Models\Order::where('status', 'pending')->first();

if (!$order) {
    echo "❌ No pending orders!\n";
    exit(1);
}

echo "Order ID: {$order->id}\n";
echo "Customer: {$order->customer->name}\n";
echo "Fare: ₱{$order->estimated_fare}\n";
echo "Status: {$order->status}\n\n";

// Test the accept order logic manually
echo "=== TESTING ACCEPTANCE LOGIC ===\n\n";

try {
    // Check wallet
    $wallet = $driver->wallet;
    if (!$wallet) {
        echo "❌ No wallet!\n";
        exit(1);
    }
    
    echo "Wallet Balance: ₱{$wallet->balance}\n";
    
    // Check driver profile
    $driverProfile = $driver->driverProfile;
    if (!$driverProfile) {
        echo "❌ No driver profile!\n";
        exit(1);
    }
    
    echo "Driver Profile ID: {$driverProfile->id}\n";
    echo "Status: {$driverProfile->status}\n\n";
    
    // Try to accept the order
    echo "Attempting to accept order...\n";
    
    $order->driver_id = $driverProfile->id;
    $order->status = 'accepted';
    $order->accepted_at = now();
    $order->save();
    
    echo "✅ Order accepted successfully!\n\n";
    echo "Order #{$order->id} is now:\n";
    echo "  Status: {$order->status}\n";
    echo "  Driver ID: {$order->driver_id}\n";
    echo "  Accepted At: {$order->accepted_at}\n";
    
} catch (\Exception $e) {
    echo "❌ Error: {$e->getMessage()}\n";
    echo "Stack trace:\n{$e->getTraceAsString()}\n";
}
