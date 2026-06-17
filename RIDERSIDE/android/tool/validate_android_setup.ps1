# Android Build Environment Validation Script for LezGo Rider
# This script verifies that all required Android tools are properly installed

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $Text" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✅ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "  ❌ $Text" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Text)
    Write-Host "  ⚠️  $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "  ℹ️  $Text" -ForegroundColor Blue
}

# Start validation
Write-Header "Android Build Setup Validation"

$allChecksPassed = $true

# Check 1: Android SDK Location
Write-Host ""
Write-Host "1️⃣  Checking Android SDK Installation..." -ForegroundColor Magenta

$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    # Try common locations
    $possiblePaths = @(
        "C:\Users\$env:USERNAME\AppData\Local\Android\sdk",
        "C:\Android\sdk"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $androidHome = $path
            break
        }
    }
}

if ($androidHome) {
    Write-Success "Android SDK found at: $androidHome"
} else {
    Write-Error-Custom "Android SDK not found. Set ANDROID_HOME environment variable."
    Write-Info "Common path: C:\Users\$env:USERNAME\AppData\Local\Android\sdk"
    $allChecksPassed = $false
}

# Check 2: cmdline-tools
Write-Host ""
Write-Host "2️⃣  Checking Android SDK cmdline-tools..." -ForegroundColor Magenta

if ($androidHome) {
    $cmdlineToolsPath = Join-Path $androidHome "cmdline-tools"
    $cmdlineToolsLatest = Join-Path $cmdlineToolsPath "latest"
    $sdkmanagerExe = Join-Path $cmdlineToolsLatest "bin" "sdkmanager.bat"
    
    if (Test-Path $sdkmanagerExe) {
        Write-Success "cmdline-tools found at: $cmdlineToolsLatest"
    } else {
        Write-Error-Custom "cmdline-tools not found at: $cmdlineToolsPath"
        Write-Info "To fix: Download from https://developer.android.com/studio/command-line-tools"
        Write-Info "Extract to: $cmdlineToolsPath\latest"
        $allChecksPassed = $false
    }
} else {
    Write-Error-Custom "Skipping cmdline-tools check (Android SDK not found)"
    $allChecksPassed = $false
}

# Check 3: Android licenses
Write-Host ""
Write-Host "3️⃣  Checking Android Licenses..." -ForegroundColor Magenta

if ($androidHome -and (Test-Path $sdkmanagerExe)) {
    $licensesPath = Join-Path $androidHome "licenses"
    
    if (Test-Path $licensesPath) {
        $acceptedLicenses = Get-ChildItem $licensesPath -File | Measure-Object
        if ($acceptedLicenses.Count -gt 0) {
            Write-Success "Android licenses accepted ($($acceptedLicenses.Count) licenses found)"
        } else {
            Write-Warning "No accepted licenses found. Run: flutter doctor --android-licenses"
            $allChecksPassed = $false
        }
    } else {
        Write-Warning "Licenses directory not found. Run: flutter doctor --android-licenses"
        $allChecksPassed = $false
    }
} else {
    Write-Warning "Skipping license check (cmdline-tools not found)"
}

# Check 4: Build Tools
Write-Host ""
Write-Host "4️⃣  Checking Android Build Tools..." -ForegroundColor Magenta

if ($androidHome) {
    $buildToolsPath = Join-Path $androidHome "build-tools"
    
    if (Test-Path $buildToolsPath) {
        $buildToolVersions = Get-ChildItem $buildToolsPath -Directory -ErrorAction SilentlyContinue
        if ($buildToolVersions.Count -gt 0) {
            $latestVersion = $buildToolVersions | Sort-Object Name -Descending | Select-Object -First 1
            Write-Success "Build-Tools found: $($latestVersion.Name)"
        } else {
            Write-Error-Custom "No Build-Tools versions installed"
            Write-Info "Install via Android Studio: Settings > Languages & Frameworks > Android SDK > SDK Tools"
            $allChecksPassed = $false
        }
    } else {
        Write-Error-Custom "Build-Tools directory not found at: $buildToolsPath"
        $allChecksPassed = $false
    }
}

# Check 5: Platform Tools
Write-Host ""
Write-Host "5️⃣  Checking Android Platform Tools..." -ForegroundColor Magenta

if ($androidHome) {
    $platformToolsPath = Join-Path $androidHome "platform-tools"
    $adbExe = Join-Path $platformToolsPath "adb.exe"
    
    if (Test-Path $adbExe) {
        Write-Success "Platform-Tools found (adb available)"
    } else {
        Write-Warning "adb not found at: $platformToolsPath"
        Write-Info "Install via Android Studio: Settings > Languages & Frameworks > Android SDK > SDK Tools"
    }
}

# Check 6: Flutter Doctor (high-level check)
Write-Host ""
Write-Host "6️⃣  Running Flutter Doctor..." -ForegroundColor Magenta

$flutterDoctor = flutter doctor -v
if ($flutterDoctor -match "Android toolchain.*OK") {
    Write-Success "Flutter detects Android toolchain as OK"
} else {
    Write-Warning "Flutter Android toolchain check may have issues. Run: flutter doctor -v"
}

# Check 7: Project files
Write-Host ""
Write-Host "7️⃣  Checking Project Configuration Files..." -ForegroundColor Magenta

$projectRoot = Split-Path -Parent -Path (Split-Path -Parent $PSScriptRoot)

$files = @(
    @{ Path = "pubspec.yaml"; Name = "pubspec.yaml" },
    @{ Path = "android/build.gradle.kts"; Name = "android/build.gradle.kts" },
    @{ Path = "android/app/build.gradle.kts"; Name = "android/app/build.gradle.kts" }
)

foreach ($file in $files) {
    $fullPath = Join-Path $projectRoot $file.Path
    if (Test-Path $fullPath) {
        Write-Success "$($file.Name) found"
    } else {
        Write-Error-Custom "$($file.Name) not found at: $fullPath"
        $allChecksPassed = $false
    }
}

# Summary
Write-Header "Validation Summary"

if ($allChecksPassed) {
    Write-Success "All checks passed! ✨"
    Write-Info "You can now build the Android APK with: flutter build apk --release"
    exit 0
} else {
    Write-Error-Custom "Some checks failed. See above for details."
    Write-Info "For detailed setup instructions, see: android/SETUP.md"
    exit 1
}
