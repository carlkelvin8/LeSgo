param(
  [string]$SecretsFile = "secrets.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$secretsPath = Join-Path $root $SecretsFile
$examplePath = Join-Path $root "secrets.example.json"

if (-not (Test-Path $secretsPath)) {
  Write-Error "Missing $SecretsFile. Copy secrets.example.json to secrets.json and fill in values."
}

$content = Get-Content $secretsPath -Raw | ConvertFrom-Json
$errors = @()

function Test-Secret([string]$name, [string]$value, [scriptblock]$validator) {
  if ([string]::IsNullOrWhiteSpace($value)) {
    $errors += "$name is missing"
    return
  }
  if ($value -like "your-*" -or $value -like "YOUR_*") {
    $errors += "$name is still a placeholder"
    return
  }
  if ($null -ne $validator -and -not (& $validator $value)) {
    $errors += "$name failed validation"
  }
}

Test-Secret "GOOGLE_MAPS_API_KEY" $content.GOOGLE_MAPS_API_KEY { param($v) $v.StartsWith("AIza") }
Test-Secret "GOOGLE_WEB_CLIENT_ID" $content.GOOGLE_WEB_CLIENT_ID { param($v) $v.Contains(".apps.googleusercontent.com") }
Test-Secret "FIREBASE_PROJECT_ID" $content.FIREBASE_PROJECT_ID { param($v) $v -notmatch "^(your-|YOUR_)" }
Test-Secret "FIREBASE_MESSAGING_SENDER_ID" $content.FIREBASE_MESSAGING_SENDER_ID { param($v) $v -match "^\d+$" }
Test-Secret "FIREBASE_API_KEY_ANDROID" $content.FIREBASE_API_KEY_ANDROID { param($v) $v.StartsWith("AIza") }
Test-Secret "FIREBASE_APP_ID_ANDROID" $content.FIREBASE_APP_ID_ANDROID { param($v) $v -match "^1:\d+:android:" }
Test-Secret "FIREBASE_API_KEY_IOS" $content.FIREBASE_API_KEY_IOS { param($v) $v.StartsWith("AIza") }
Test-Secret "FIREBASE_APP_ID_IOS" $content.FIREBASE_APP_ID_IOS { param($v) $v -match "^1:\d+:ios:" }

if ($errors.Count -gt 0) {
  Write-Host "Secrets validation failed:" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  Write-Host ""
  Write-Host "Fill all values in secrets.json, then run: .\tool\sync_secrets.ps1"
  Write-Host "Build with: flutter run --dart-define-from-file=secrets.json"
  exit 1
}

Write-Host "All secrets validated." -ForegroundColor Green
