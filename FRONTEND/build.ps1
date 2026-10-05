# LeSGo Customer App - Build Script
# Usage: .\build.ps1 [apk|appbundle|run]

param(
    [Parameter(Position=0)]
    [ValidateSet("apk", "appbundle", "run", "clean")]
    [string]$Command = "apk"
)

$ErrorActionPreference = "Stop"
$SecretsFile = "secrets.json"

if ($Command -eq "clean") {
    Write-Host "`n> flutter clean && flutter pub get" -ForegroundColor Green
    flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter pub get
    exit $LASTEXITCODE
}

# Validate every build-time value and the Android Firebase/OAuth package mapping.
& (Join-Path $PSScriptRoot "tool\validate_secrets.ps1") -SecretsFile $SecretsFile
if (-not $?) { exit 1 }

Write-Host "Building LeSGo Customer App..." -ForegroundColor Cyan
Write-Host "Secrets: $SecretsFile" -ForegroundColor Gray

switch ($Command) {
    "apk" {
        Write-Host "`n> flutter build apk --release" -ForegroundColor Green
        flutter build apk --release --dart-define-from-file=$SecretsFile
        if ($LASTEXITCODE -eq 0) {
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            $destPath = "..\apk\lesgo-customer-release.apk"
            if (Test-Path $apkPath) {
                Copy-Item $apkPath $destPath -Force
                Write-Host "`nAPK copied to: $destPath" -ForegroundColor Green
                Write-Host "Size: $([math]::Round((Get-Item $destPath).Length / 1MB, 2)) MB" -ForegroundColor Gray
            }
        }
    }
    "appbundle" {
        Write-Host "`n> flutter build appbundle --release" -ForegroundColor Green
        flutter build appbundle --release --dart-define-from-file=$SecretsFile
        if ($LASTEXITCODE -eq 0) {
            $aabPath = "build\app\outputs\bundle\release\app-release.aab"
            $destPath = "..\apk\lesgo-customer-release.aab"
            if (Test-Path $aabPath) {
                Copy-Item $aabPath $destPath -Force
                Write-Host "`nAAB copied to: $destPath" -ForegroundColor Green
            }
        }
    }
    "run" {
        Write-Host "`n> flutter run --dart-define-from-file" -ForegroundColor Green
        flutter run --dart-define-from-file=$SecretsFile
    }
}
