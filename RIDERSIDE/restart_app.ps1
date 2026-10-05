# Script to properly restart the Flutter app with all changes

Write-Host "🔄 Restarting RIDERSIDE app with new status changes..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean build
Write-Host "1️⃣ Cleaning build cache..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "2️⃣ Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies updated" -ForegroundColor Green
Write-Host ""

# Step 3: Run the app
Write-Host "3️⃣ Starting app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "📱 The app will now start with the new statuses enabled:" -ForegroundColor Cyan
Write-Host "   ✅ Driver Has Arrived" -ForegroundColor Green
Write-Host "   ✅ In Progress" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Yellow
Write-Host ""

flutter run

