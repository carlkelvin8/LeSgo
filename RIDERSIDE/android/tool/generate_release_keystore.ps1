param(
  [string]$AppName = "lesgo-rider",
  [string]$KeyAlias = "lesgo-rider",
  [string]$StorePassword,
  [string]$KeyPassword,
  [int]$ValidityDays = 10000
)

$ErrorActionPreference = "Stop"

# Release passwords are never hardcoded. Provide them via -StorePassword /
# -KeyPassword (e.g. from your secrets manager) or get prompted interactively.
if ([string]::IsNullOrWhiteSpace($StorePassword)) {
  $secure = Read-Host "Keystore store password" -AsSecureString
  $StorePassword = [System.Net.NetworkCredential]::new("", $secure).Password
}
if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
  $KeyPassword = $StorePassword
}
if ([string]::IsNullOrWhiteSpace($StorePassword)) {
  Write-Error "No store password supplied - aborting."
}
$androidRoot = Split-Path -Parent $PSScriptRoot
$keystoreName = "$AppName-release.jks"
$keystorePath = Join-Path $androidRoot $keystoreName
$keyPropsPath = Join-Path $androidRoot "key.properties"
$keyPropsExample = Join-Path $androidRoot "key.properties.example"

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
  $javaHome = $env:JAVA_HOME
  if ($javaHome) {
    $keytoolPath = Join-Path $javaHome "bin\keytool.exe"
    if (Test-Path $keytoolPath) { $keytool = $keytoolPath }
  }
}
if (-not $keytool) {
  Write-Error "keytool not found. Install JDK and ensure JAVA_HOME is set."
}

$dname = "CN=LezGo Rider, OU=Mobile, O=LezGo, L=Manila, ST=Metro Manila, C=PH"

if (-not (Test-Path $keystorePath)) {
  Write-Host "Creating release keystore: $keystorePath"
  & $keytool -genkeypair -v `
    -keystore $keystorePath `
    -storetype JKS `
    -storepass $StorePassword `
    -keypass $KeyPassword `
    -keyalg RSA `
    -keysize 2048 `
    -validity $ValidityDays `
    -alias $KeyAlias `
    -dname $dname
} else {
  Write-Host "Keystore already exists: $keystorePath"
}

$props = @"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=$keystoreName
"@

Set-Content -Path $keyPropsPath -Value $props -NoNewline
Write-Host "Wrote $keyPropsPath"

if (-not (Test-Path $keyPropsExample)) {
  @"
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=$KeyAlias
storeFile=$keystoreName
"@ | Set-Content -Path $keyPropsExample
}

Write-Host ""
Write-Host "Release signing ready for RIDERSIDE."
Write-Host "Build: flutter build apk --release --dart-define-from-file=secrets.json"
Write-Host "IMPORTANT: Back up $keystoreName and store passwords in your secrets manager for Play Store."
