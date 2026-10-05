# LeSGo Rider App - Build Script
# Usage: .\build.ps1 [apk|appbundle|run]

param(
    [Parameter(Position=0)]
    [ValidateSet("apk", "appbundle", "run", "clean")]
    [string]$Command = "apk"
)

$ErrorActionPreference = "Stop"
$SecretsFile = "secrets.json"

# Verify secrets.json exists
if (-not (Test-Path $SecretsFile)) {
    Write-Host "ERROR: $SecretsFile not found!" -ForegroundColor Red
    Write-Host "Copy secrets.example.json to secrets.json and fill in your values." -ForegroundColor Yellow
    exit 1
}

# Verify secrets.json has actual values
$secrets = Get-Content $SecretsFile | ConvertFrom-Json
if ($secrets.GOOGLE_MAPS_API_KEY -like "your-*" -or $secrets.GOOGLE_MAPS_API_KEY -eq "") {
    Write-Host "ERROR: secrets.json contains placeholder values!" -ForegroundColor Red
    exit 1
}

Write-Host "Building LeSGo Rider App..." -ForegroundColor Cyan

switch ($Command) {
    "apk" {
        Write-Host "`n> flutter build apk --release" -ForegroundColor Green
        flutter build apk --release --dart-define-from-file=$SecretsFile
        if ($LASTEXITCODE -eq 0) {
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            $destPath = "..\apk\lesgo-rider-release.apk"
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
    }
    "run" {
        Write-Host "`n> flutter run --dart-define-from-file" -ForegroundColor Green
        flutter run --dart-define-from-file=$SecretsFile
    }
    "clean" {
        flutter clean
        flutter pub get
    }
}
