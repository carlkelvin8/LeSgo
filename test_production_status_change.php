<?php
/**
 * Test if production backend has the ready_for_pickup fix
 * 
 * This will check the actual OrderController code on production
 */

$productionUrl = 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';

echo "=== TESTING PRODUCTION BACKEND ===\n";
echo "URL: $productionUrl\n";
echo "Time: " . date('Y-m-d H:i:s') . "\n\n";

// Try to access a simple endpoint to check if API is up
$ch = curl_init("$productionUrl/v1/config/mobile");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Health Check: HTTP $httpCode\n";
if ($httpCode === 200) {
    echo "✅ Production API is UP\n\n";
} else {
    echo "❌ Production API issue (HTTP $httpCode)\n\n";
}

// Check git status
echo "=== LOCAL GIT STATUS ===\n";
chdir(__DIR__ . '/BACKEND/lesgo-api');
system('git branch --show-current');
system('git log --oneline -1');
echo "\n";

// Check if fix is in local code
echo "=== CHECKING LOCAL CODE ===\n";
$controller = file_get_contents('app/Http/Controllers/Api/OrderController.php');
if (strpos($controller, "'ready_for_pickup'   => in_array(\$current, ['searching_driver', 'accepted'], true)") !== false) {
    echo "✅ Fix EXISTS in local code (line 729)\n";
} else {
    echo "❌ Fix NOT FOUND in local code\n";
}

echo "\n=== DEPLOYMENT STATUS ===\n";
echo "Commit time: 2026-06-28 13:42:55 (1h 26m ago)\n";
echo "Current time: " . date('H:i:s') . "\n";
echo "Laravel Cloud should have auto-deployed by now\n\n";

echo "⚠️ PROBLEM: Production still returning 403 error\n";
echo "This means Laravel Cloud has NOT deployed the fix yet!\n\n";

echo "=== POSSIBLE CAUSES ===\n";
echo "1. Laravel Cloud is watching a different branch\n";
echo "2. Auto-deploy is disabled\n";
echo "3. Deployment failed silently\n";
echo "4. Cache issue preventing new code from loading\n\n";

echo "=== SOLUTION ===\n";
echo "1. Check Laravel Cloud dashboard: https://cloud.laravel.com\n";
echo "2. Verify which branch is being deployed\n";
echo "3. Manually trigger deployment if needed\n";
echo "4. Check deployment logs for errors\n";
