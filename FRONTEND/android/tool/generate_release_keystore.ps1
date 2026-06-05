param(
  [string]$AppName = "lesgo-customer",
  [string]$KeyAlias = "lesgo-customer",
  [string]$StorePassword = "LesgoCustomerRelease2026!",
  [string]$KeyPassword = "LesgoCustomerRelease2026!",
  [int]$ValidityDays = 10000
)

$ErrorActionPreference = "Stop"
$androidRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $androidRoot "$AppName-release.jks"
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

$dname = "CN=LezGo Customer, OU=Mobile, O=LezGo, L=Manila, ST=Metro Manila, C=PH"

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

$keystoreFileName = Split-Path $keystorePath -Leaf
$props = @"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=$keystoreFileName
"@

Set-Content -Path $keyPropsPath -Value $props -NoNewline
Write-Host "Wrote $keyPropsPath"

if (-not (Test-Path $keyPropsExample)) {
  @"
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=$KeyAlias
storeFile=$keystoreFileName
"@ | Set-Content -Path $keyPropsExample
}

Write-Host ""
Write-Host "Release signing ready for FRONTEND (LezGo customer app)."
Write-Host "Build: flutter build apk --release --dart-define-from-file=secrets.json"
Write-Host "IMPORTANT: Back up $keystoreFileName and store passwords in your secrets manager for Play Store."
