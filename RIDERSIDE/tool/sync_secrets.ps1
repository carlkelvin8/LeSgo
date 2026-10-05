param(
  [string]$SecretsFile = "secrets.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$secretsPath = Join-Path $root $SecretsFile
$examplePath = Join-Path $root "secrets.example.json"
$iosSecretsPath = Join-Path $root "ios/Flutter/Secrets.xcconfig"
$googleServicesPath = Join-Path $root "android/app/google-services.json"
$googlePlistPath = Join-Path $root "ios/Runner/GoogleService-Info.plist"

if (-not (Test-Path $secretsPath)) {
  if (Test-Path $examplePath) {
    Copy-Item $examplePath $secretsPath
    Write-Host "Created $SecretsFile from secrets.example.json."
  } else {
    Write-Error "Missing $SecretsFile. Copy secrets.example.json and fill in values."
  }
}

$content = Get-Content $secretsPath -Raw | ConvertFrom-Json

function Require([string]$name, [string]$value) {
  if ([string]::IsNullOrWhiteSpace($value) -or $value -like "your-*" -or $value -like "YOUR_*") {
    Write-Warning "$name is not configured in $SecretsFile."
  }
}

Require "GOOGLE_MAPS_API_KEY" $content.GOOGLE_MAPS_API_KEY
Require "FIREBASE_PROJECT_ID" $content.FIREBASE_PROJECT_ID

$mapsKey = $content.GOOGLE_MAPS_API_KEY
Set-Content -Path $iosSecretsPath -Value "GOOGLE_MAPS_API_KEY=$mapsKey" -NoNewline
Write-Host "Synced ios/Flutter/Secrets.xcconfig"

$projectId = $content.FIREBASE_PROJECT_ID
$senderId = $content.FIREBASE_MESSAGING_SENDER_ID
$androidApiKey = $content.FIREBASE_API_KEY_ANDROID
$androidAppId = $content.FIREBASE_APP_ID_ANDROID

$googleServices = @{
  project_info = @{
    project_number = $senderId
    project_id = $projectId
    storage_bucket = "$projectId.firebasestorage.app"
  }
  client = @(
    @{
      client_info = @{
        mobilesdk_app_id = $androidAppId
        android_client_info = @{
          package_name = "com.lesgo.rider"
        }
      }
      oauth_client = @()
      api_key = @(
        @{
          current_key = $androidApiKey
        }
      )
      services = @{
        appinvite_service = @{
          other_platform_oauth_client = @()
        }
      }
    }
  )
  configuration_version = "1"
} | ConvertTo-Json -Depth 8

Set-Content -Path $googleServicesPath -Value $googleServices -Encoding UTF8
Write-Host "Synced android/app/google-services.json"

$iosApiKey = $content.FIREBASE_API_KEY_IOS
$iosAppId = $content.FIREBASE_APP_ID_IOS
$iosBundle = if ($content.FIREBASE_IOS_BUNDLE_ID) { $content.FIREBASE_IOS_BUNDLE_ID } else { "com.lesgo.rider" }

$plist = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>$iosApiKey</string>
	<key>GCM_SENDER_ID</key>
	<string>$senderId</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>$iosBundle</string>
	<key>PROJECT_ID</key>
	<string>$projectId</string>
	<key>STORAGE_BUCKET</key>
	<string>$projectId.firebasestorage.app</string>
	<key>IS_ADS_ENABLED</key>
	<false></false>
	<key>IS_ANALYTICS_ENABLED</key>
	<false></false>
	<key>IS_APPINVITE_ENABLED</key>
	<true></true>
	<key>IS_GCM_ENABLED</key>
	<true></true>
	<key>IS_SIGNIN_ENABLED</key>
	<true></true>
	<key>GOOGLE_APP_ID</key>
	<string>$iosAppId</string>
</dict>
</plist>
"@

Set-Content -Path $googlePlistPath -Value $plist -Encoding UTF8
Write-Host "Synced ios/Runner/GoogleService-Info.plist"
Write-Host "Done. Build with: flutter run --dart-define-from-file=secrets.json"
