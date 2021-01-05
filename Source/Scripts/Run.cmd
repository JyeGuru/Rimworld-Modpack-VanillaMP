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

Push-Location ".\Game"

Write-Host "Starting Rimworld ..."
Start-Process -FilePath ".\RimWorldWin64.exe" -ArgumentList """-savedatafolder=$(Resolve-Path $configpath)"""

if ($hosting) {
    Write-Host "Done! Game loaded in Host Mode." -ForegroundColor Green

    # Script block required due to mod bug: https://github.com/rwmt/Multiplayer/issues/124
    while ($true) {
        Write-Host "Watching for bugged arbiter processes [Press Q to kill all] ..." -ForegroundColor Blue
        while (!([Console]::KeyAvailable)) {
            Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "RimWorldWin64.exe" } | Foreach-Object {
                if (($_.CommandLine -like "*-arbiter*") -and ($_.CommandLine -like "*-savedatafolder=""*")) {
                    $arbiterpid = $_.ProcessId
                    $commandline = $_.CommandLine -Replace '^.*RimWorldWin64.exe\" ' -Replace '-savedatafolder.*$', """-savedatafolder=$(Resolve-Path $configpath)"""
                    Write-Host "Arbiter found: PID $arbiterpid" -ForegroundColor Green
                    Write-Host "Original Command: $($_.CommandLine)"
                    Write-Host "Fixed Command: $commandline"
                    Write-Host "- Stopping ..."
                    Stop-Process -Id $arbiterpid -Force
                    Write-Host "- Restarting ..."
                    Start-Process -FilePath ".\RimWorldWin64.exe" -ArgumentList $commandline
                } 
            }
            Start-Sleep -Seconds 1      
        }
        $pressed = [Console]::ReadKey($true)
        if ($pressed.Key -eq "Q") {
            Write-Host "- Force-Kill Triggered ..."
            Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "RimWorldWin64.exe" } | Foreach-Object {
                if ($_.CommandLine -like "*-arbiter*") {
                    $id = $_.ProcessId
                    Stop-Process -Id $id -Force
                    Write-Host "Force killed PID $id!" -ForegroundColor Green
                }
            }
        }
    } # End workaround
}
else {
    Write-Host "Done! Game loaded in Client Mode. You can close this window." -ForegroundColor Green
    Start-Sleep -Seconds 60
}