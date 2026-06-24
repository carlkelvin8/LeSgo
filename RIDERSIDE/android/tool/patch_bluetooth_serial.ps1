# Patches flutter_bluetooth_serial compileSdk for release APK builds (lStar resource error).
$cacheRoot = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
$matches = Get-ChildItem -Path $cacheRoot -Filter "flutter_bluetooth_serial-*" -Directory -ErrorAction SilentlyContinue
if (-not $matches) {
    Write-Error "flutter_bluetooth_serial not found in pub cache. Run: flutter pub get"
    exit 1
}

foreach ($dir in $matches) {
    $buildGradle = Join-Path $dir.FullName "android\build.gradle"
    if (-not (Test-Path $buildGradle)) { continue }
    $content = Get-Content $buildGradle -Raw
    if ($content -match "compileSdkVersion 3[0-3]") {
        $content = $content -replace "compileSdkVersion 3[0-3]", "compileSdkVersion 34"
        Set-Content -Path $buildGradle -Value $content -NoNewline
        Write-Host "Patched $($dir.Name) compileSdk -> 34"
    } else {
        Write-Host "Already patched or unsupported: $($dir.Name)"
    }
}
