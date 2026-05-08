# PowerShell script to generate JSON serialization code

Write-Host "🔨 Generating JSON serialization code for DTOs..." -ForegroundColor Cyan

Set-Location $PSScriptRoot

flutter pub run build_runner build --delete-conflicting-outputs

Write-Host "✅ Done! JSON serialization code generated." -ForegroundColor Green
