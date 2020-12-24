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

$configpath = "..\Config" # Relative to game executable, or full absolute

$hosting = Get-ChildItem -File -Filter "host*" # Create a file called "host" (or host.*) in the folder to activate host mode

Set-Location ".\Game"

Write-Host "Starting Rimworld ..."
Start-Process -FilePath ".\RimWorldWin64.exe" -ArgumentList """-savedatafolder=$(Resolve-Path $configpath)"""

if ($hosting) {
    Write-Host "Done! Game loaded in Host Mode." -ForegroundColor Green

    Write-Host "Waiting for arbiter process ..." -ForegroundColor Blue
    while (!$Script:arbiterpid) {
        Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "RimWorldWin64.exe" } | Foreach-Object {
            if ($_.CommandLine -like "*-arbiter*") {
                $Script:arbiterpid = $_.ProcessId
                $Script:commandline = $_.CommandLine -Replace '^.*RimWorldWin64.exe\" ' -Replace '-savedatafolder.*$', """-savedatafolder=$(Resolve-Path $configpath)"""
            } 
        }
    }

    Write-Host "Arbiter found: PID $arbiterpid" -ForegroundColor Green
    Write-Host "Arbiter Command: $commandline"
    Write-Host "- Stopping ..."
    Stop-Process -Id $arbiterpid -Force
    Write-Host "- Restarting ..."
    Start-Process -FilePath ".\RimWorldWin64.exe" -ArgumentList $commandline

    Start-Sleep -Seconds 5
    $Script:arbiterpid = $false
    while (!$Script:arbiterpid) {
        Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "RimWorldWin64.exe" } | Foreach-Object {
            if ($_.CommandLine -like "*-arbiter*") {
                $Script:arbiterpid = $_.ProcessId
            } 
        }
    }

    Write-Host "Done! Arbiter should join shortly." -ForegroundColor Green
    Write-Host "Waiting for the Arbiter to exit. Press a key to kill it instead ..." -ForegroundColor Blue
    while (Get-Process -Id $arbiterpid -ErrorAction SilentlyContinue) {
        if (([Console]::KeyAvailable)) {
            Write-Host "- Killing arbiter ..."
            Stop-Process -Id $arbiterpid -Force
        }
        Start-Sleep -Seconds 1
    }

    Write-Host "Done! Arbiter should have exited now. You can close this window." -ForegroundColor Green
    Start-Sleep -Seconds 60
}
else {
    Write-Host "Done! Game loaded in Client Mode. You can close this window." -ForegroundColor Green
    Start-Sleep -Seconds 60
}