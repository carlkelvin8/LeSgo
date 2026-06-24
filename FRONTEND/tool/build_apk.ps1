$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

flutter build apk --release --dart-define-from-file=secrets.json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkDir = Join-Path (Split-Path -Parent $root) "apk"
$src = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$dest = Join-Path $apkDir "lesgo-customer-release.apk"

New-Item -ItemType Directory -Force -Path $apkDir | Out-Null
Copy-Item -Force $src $dest

Write-Host ""
Write-Host "APK ready: $dest" -ForegroundColor Green
