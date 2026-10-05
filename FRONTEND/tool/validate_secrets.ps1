param(
  [string]$SecretsFile = "secrets.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$secretsPath = Join-Path $root $SecretsFile
$examplePath = Join-Path $root "secrets.example.json"
$googleServicesPath = Join-Path $root "android/app/google-services.json"
$androidPackageName = "com.lesgo_customer"
$requiredAndroidOAuthSha1 = @(
  "0cd4c1536873c5eb8f32983dafb78ae9bcc63a2f", # local debug/emulator
  "fe33d34c7bedf535ead2547000d4f843ee4b9f90"  # Google Play App Signing
)

if (-not (Test-Path $secretsPath)) {
  Write-Error "Missing $SecretsFile. Copy secrets.example.json to secrets.json and fill in values."
}

$content = Get-Content $secretsPath -Raw | ConvertFrom-Json
$errors = @()

function Test-Secret([string]$name, [string]$value, [scriptblock]$validator) {
  if ([string]::IsNullOrWhiteSpace($value)) {
    $script:errors += "$name is missing"
    return
  }
  if ($value -like "your-*" -or $value -like "YOUR_*") {
    $script:errors += "$name is still a placeholder"
    return
  }
  if ($null -ne $validator -and -not (& $validator $value)) {
    $script:errors += "$name failed validation"
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

if (-not (Test-Path $googleServicesPath)) {
  $errors += "android/app/google-services.json is missing"
} else {
  try {
    $googleServices = Get-Content $googleServicesPath -Raw | ConvertFrom-Json
    $androidClients = @($googleServices.client | Where-Object {
      $_.client_info.android_client_info.package_name -eq $androidPackageName
    })

    if ($androidClients.Count -ne 1) {
      $errors += "google-services.json must contain exactly one client for $androidPackageName"
    } else {
      $androidClient = $androidClients[0]
      if ($androidClient.client_info.mobilesdk_app_id -ne $content.FIREBASE_APP_ID_ANDROID) {
        $errors += "FIREBASE_APP_ID_ANDROID does not match the $androidPackageName Firebase app"
      }

      $webClients = @($androidClient.oauth_client | Where-Object {
        $_.client_type -eq 3 -and $_.client_id -eq $content.GOOGLE_WEB_CLIENT_ID
      })
      if ($webClients.Count -eq 0) {
        $errors += "GOOGLE_WEB_CLIENT_ID does not match google-services.json"
      }

      $certificateClients = @($androidClient.oauth_client | Where-Object {
        $_.client_type -eq 1 -and
        $_.android_info.package_name -eq $androidPackageName -and
        -not [string]::IsNullOrWhiteSpace($_.android_info.certificate_hash)
      })
      if ($certificateClients.Count -eq 0) {
        $errors += "google-services.json has no Android OAuth certificate for $androidPackageName"
      }

      $configuredSha1 = @($certificateClients | ForEach-Object {
        $_.android_info.certificate_hash.ToLowerInvariant()
      })
      foreach ($requiredSha1 in $requiredAndroidOAuthSha1) {
        if ($configuredSha1 -notcontains $requiredSha1) {
          $errors += "google-services.json is missing required Android OAuth SHA-1 $requiredSha1"
        }
      }
    }
  } catch {
    $errors += "android/app/google-services.json is invalid JSON"
  }
}

if ($errors.Count -gt 0) {
  Write-Host "Secrets validation failed:" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  Write-Host ""
  Write-Host "Fill all values in secrets.json, then run: .\tool\sync_secrets.ps1"
  Write-Host "Build with: flutter run --dart-define-from-file=secrets.json"
  exit 1
}

Write-Host "All secrets validated." -ForegroundColor Green
