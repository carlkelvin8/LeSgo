Write-Host "Triggering Flutter Hot Reload..."
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("r")
Write-Host "Hot reload command sent!"