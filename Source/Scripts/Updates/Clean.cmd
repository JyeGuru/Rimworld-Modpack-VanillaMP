<# : Begin batch (batch script is in commentary of powershell v2.0+)
@echo off
: Use local variables
setlocal
: Invoke this file as powershell expression
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression $($ScriptHome = '%~dp0'; [System.IO.File]::ReadAllText('%~dpf0'))"
: Restore environment variables present before setlocal and restore current directory
endlocal
: End batch - go to end of file
goto:eof
#>

Push-Location ".."

Write-Host "Cleaning up installation folder!" -ForegroundColor Yellow

$MPModXml = ".\Config\Config\Mod_1752864297_MultiplayerMod.xml"
if (Test-Path $MPModXml) {
    Write-Host "- Saving Username ..." -ForegroundColor Yellow
    [xml]$xml = Get-Content $MPModXml
    $username = $xml.SettingsBlock.ModSettings.username
    Set-Content -Path ".\Updates\username.txt" -Value $username -NoNewLine -Force
    Write-Host "  Username: $username" -ForegroundColor Blue
}

if (Test-Path ".\Config") {
    Write-Host "- Backing up saves/etc ..." -ForegroundColor Yellow
    New-Item -Path ".\Backup" -ItemType Directory -Force | Out-Null
    $output = @()
    $output += Get-ChildItem -Path ".\Config" -Directory -Filter "Saves" | Copy-Item -Destination ".\Backup" -Recurse -Force -PassThru
    $output += Get-ChildItem -Path ".\Config" -Directory -Filter "MpReplays" | Copy-Item -Destination ".\Backup" -Recurse -Force -PassThru
    $output += Get-ChildItem -Path ".\Config" -Directory -Filter "Scenarios" | Copy-Item -Destination ".\Backup" -Recurse -Force -PassThru
    $output += Get-ChildItem -Path ".\Config" -Directory -Filter "ModLists" | Copy-Item -Destination ".\Backup" -Recurse -Force -PassThru
    if ($output.Count -gt 0) {
        $output.FullName.Replace($pwd.Path, ".")
    }
}

Write-Host "- Removing Configs ..." -ForegroundColor Yellow
Get-ChildItem -Directory -Filter "Config" | Remove-Item -Recurse -Force

Write-Host "- Removing Game Files ..." -ForegroundColor Yellow
Get-ChildItem -Directory -Filter "Game" | Remove-Item -Recurse -Force

Write-Host "- Removing Update Hashes ..." -ForegroundColor Yellow
Get-ChildItem -Path ".\Updates" -Filter "*.hash" | Remove-Item -Force

Write-Host "Done! Please close this window and run the updater." -ForegroundColor Green

Start-Sleep -Seconds 300