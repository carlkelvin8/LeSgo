$ErrorActionPreference = "Stop"
$androidRoot = Split-Path -Parent $PSScriptRoot
$keyProps = Join-Path $androidRoot "key.properties"
$example = Join-Path $androidRoot "key.properties.example"

$errors = @()

if (-not (Test-Path $keyProps)) {
  $errors += "Missing android/key.properties - run android/tool/generate_release_keystore.ps1"
} else {
  $lines = Get-Content $keyProps
  foreach ($name in @("storePassword", "keyPassword", "keyAlias", "storeFile")) {
    $line = $lines | Where-Object { $_ -match "^$name=" } | Select-Object -First 1
    if (-not $line) {
      $errors += "key.properties missing $name="
    } elseif ($line -match "your-") {
      $errors += "key.properties has placeholder value for $name"
    }
  }
  $storeFileLine = ($lines | Where-Object { $_ -match "^storeFile=" } | Select-Object -First 1) -replace "^storeFile=", ""
  if ($storeFileLine) {
    $keystorePath = Join-Path $androidRoot $storeFileLine
    if (-not (Test-Path $keystorePath)) {
      $errors += "Keystore not found: $keystorePath"
    }
  }
}

if ($errors.Count -gt 0) {
  foreach ($e in $errors) { Write-Host "ERROR: $e" -ForegroundColor Red }
  exit 1
}

Write-Host "RIDERSIDE release signing OK (key.properties + keystore present)."
exit 0
