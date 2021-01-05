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

$ConfigFile = ".\config.json"

if (Test-Path $ConfigFile) {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
}
else {
    Write-Host "ERROR: Critical file(s) missing, please fix this." -ForegroundColor Red
    break
}

$GamePath = $Config.GamePath
if ((!$GamePath) -or (!(Test-Path $GamePath))) {
    Write-Host "ERROR: Invalid game path in config." -ForegroundColor Red
}

Write-Host "Synching game folder to temp ..." -ForegroundColor Yellow

Write-Host "- Creating temp folder ..."
$TempFolderPath = Join-Path $Env:Temp $(New-Guid); New-Item -Type Directory -Path $TempFolderPath -Force | Out-Null

Write-Host "- Copying ..."
robocopy $GamePath $TempFolderPath /XD "Mods" /Z /J /E /PURGE /R:5 /W:1 /NDL | Out-Null

Write-Host "Cleaning up game folder ..." -ForegroundColor Yellow

Write-Host "- Removing 32-Bit Data folder ..."
Get-ChildItem $TempFolderPath -Directory -Filter "RimWorldWin_Data" -Depth 1 | Remove-Item -Recurse -Force

Write-Host "- Removing Source folder ..."
Get-ChildItem $TempFolderPath -Directory -Filter "Source" -Depth 1 | Remove-Item -Recurse -Force

Write-Host "- Removing other unneeded files ..."
Get-ChildItem $TempFolderPath -File -Include "*.log", "arbiter_log.txt", "EULA.txt", "Licenses.txt", "Readme.txt", "ModUpdating.txt" -Recurse | Remove-Item -Force

Write-Host "Synching out of temp ..." -ForegroundColor Yellow
    
Write-Host "- Copying ..."
robocopy "$TempFolderPath" ".\Game" /XD "Mods" /Z /J /E /PURGE /R:5 /W:1 /NDL | Out-Null

Write-Host "- Removing temp folder ..."
Remove-Item $TempFolderPath -Recurse -Force

Write-Host "Removing package file ..." -ForegroundColor Yellow
Get-ChildItem "." -File -Filter "Game.7z" -Depth 1 | Remove-Item -Force
Write-Host "- Please regenerate package files!" -ForegroundColor Blue

Write-Host "Done! Please close this window." -ForegroundColor Green

Start-Sleep -Seconds 300