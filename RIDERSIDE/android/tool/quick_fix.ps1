# Quick Fix Script for Android Build Issues
# Fixes common issues and prepares environment for building

param(
    [switch]$AcceptAll = $false
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "▶ $Text" -ForegroundColor Magenta
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor Blue
}

function Confirm-Action {
    param([string]$Message)
    
    if ($AcceptAll) {
        return $true
    }
    
    $response = Read-Host "$Message (y/n)"
    return $response -eq "y" -or $response -eq "Y"
}

Write-Header "LezGo Rider - Android Build Quick Fix"

# Step 1: Flutter Clean
Write-Step "Step 1: Cleaning Flutter build artifacts..."
try {
    flutter clean
    Write-Success "Flutter clean completed"
} catch {
    Write-Error-Custom "Flutter clean failed: $_"
}

# Step 2: Clean Android build
Write-Step "Step 2: Cleaning Android build..."
try {
    $androidPath = "android"
    if (Test-Path "$androidPath/.gradle") {
        Remove-Item "$androidPath/.gradle" -Recurse -Force
        Write-Success "Removed .gradle directory"
    }
    
    if (Test-Path "$androidPath/app/build") {
        Remove-Item "$androidPath/app/build" -Recurse -Force
        Write-Success "Removed build directory"
    }
} catch {
    Write-Error-Custom "Android clean failed: $_"
}

# Step 3: Get dependencies
Write-Step "Step 3: Getting Flutter dependencies..."
try {
    flutter pub get
    Write-Success "Dependencies updated"
} catch {
    Write-Error-Custom "flutter pub get failed: $_"
}

# Step 4: Check Flutter doctor
Write-Step "Step 4: Running Flutter doctor..."
try {
    flutter doctor -v
} catch {
    Write-Error-Custom "Flutter doctor failed: $_"
}

# Step 5: Validate Android setup
Write-Step "Step 5: Validating Android setup..."
$scriptPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "validate_android_setup.ps1"
if (Test-Path $scriptPath) {
    & $scriptPath
} else {
    Write-Error-Custom "Validation script not found at: $scriptPath"
}

# Step 6: Accept Android licenses
Write-Step "Step 6: Checking Android licenses..."
if (Confirm-Action "Accept all Android licenses?") {
    try {
        echo "y" | flutter doctor --android-licenses > $null 2>&1
        Write-Success "Android licenses accepted"
    } catch {
        Write-Error-Custom "Failed to accept licenses: $_"
    }
}

Write-Header "Quick Fix Complete!"
Write-Success "Your environment should now be ready to build"
Write-Info "Next steps:"
Write-Info "  - For debug build: flutter build apk --debug"
Write-Info "  - For release build: flutter build apk --release"
Write-Info "  - For App Bundle: flutter build appbundle --release"
