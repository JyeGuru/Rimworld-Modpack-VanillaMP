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

Function Download-File ($Uri, $OutputFile) {

    Write-Host "Processing: $OutputFile" -ForegroundColor Yellow

    if (!(Test-Path $OutputFile) ) {
        Write-Host "- Downloading file ..."
        Start-BitsTransfer -Source $Uri -Destination $OutputFile -TransferType Download -DisplayName "Downloading $OutputFile" -Description "Please wait ..." -Priority Foreground
    }
    else {
        $remotedate = (Invoke-WebRequest -UseBasicParsing -Uri $Uri -Method Head).Headers["Last-Modified"] | Get-Date
        $localdate = (Get-Item $OutputFile).LastWriteTime | Get-Date

        if ($remotedate -gt $localdate) {
            Write-Host "- Remote file is newer, downloading ..."
            Start-BitsTransfer -Source $Uri -Destination $OutputFile -TransferType Download -DisplayName "Downloading $OutputFile" -Description "Please wait ..." -Priority Foreground
        }
        else {
            Write-Host "- Remote file not updated, using cached download."
        }
    }
}

function Load-Module ($m) {
    if (Get-Module | Where-Object { $_.Name -eq $m }) {
        write-host "- Module $m is already imported." -ForegroundColor Green
    }
    else {
        if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $m }) {
            write-host "- Module $m imported." -ForegroundColor Green
            Import-Module $m
        }
        else {
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }) {
                write-host "- Module $m not available - installing." -ForegroundColor Yellow
                Install-Module -Name $m -Force -Scope CurrentUser
                Import-Module $m
            }
            else {
                write-host "Module $m not imported, not available and not in online gallery, exiting." -ForegroundColor Red
                EXIT 1
            }
        }
    }
}

Write-Host "Rimworld Multiplayer Update Script" -ForegroundColor Green
Write-Host '***************************************' -ForegroundColor Blue
Write-Host '*  ("`-""-/").___..--"""`-._          *' -ForegroundColor Blue
Write-Host '*   `6_ 6  )   `-.  (     ).`-.__.`)  *' -ForegroundColor Blue
Write-Host '*    (_Y_.)  ._   )  `._ `. ``-..-`   *' -ForegroundColor Blue
Write-Host '*     _..`--"_..-_/  /--`_.`_         *' -ForegroundColor Blue
Write-Host '*    ((((.-``  ((((.`  (((.-"         *' -ForegroundColor Blue
Write-Host '*             (C) Grumpy Leopard 2020 *' -ForegroundColor Blue
Write-Host '***************************************' -ForegroundColor Blue

Push-Location ".\Updates"

$MPModXml = "..\Config\Config\Mod_1752864297_MultiplayerMod.xml"
if (Test-Path $MPModXml) {
    Write-Host "- Saving Username ..." -ForegroundColor Yellow
    [xml]$xml = Get-Content $MPModXml
    $username = $xml.SettingsBlock.ModSettings.username
    if ($username -eq "ChangeThis") {
        Write-Host "  Username still default, skipped." -ForegroundColor Blue
    }
    else {
        Set-Content -Path ".\username.txt" -Value $username -NoNewline -Force
        Write-Host "  Username: $username" -ForegroundColor Blue
    }
}

$downloads = Get-Content ".\update.json" | ConvertFrom-Json

$downloads | Where-Object { $_.Uri } | ForEach-Object {
    Download-File -Uri $_.Uri -OutputFile $_.Filename
}

Get-ChildItem "." -Filter *.7z | ForEach-Object {
    if (Test-Path "$($_.Name).hash") {
        $oldhash = Get-Content "$($_.Name).hash"
    }
    else {
        $oldhash = ""
    }
    $newhash = Get-FileHash $_

    if ($oldhash -eq $newhash) {
        Write-Host "No changes to $($_.Name) - Hashes Match" -ForegroundColor Green
    }
    else {
        Write-Host "Update detected: $($_.Name)" -ForegroundColor Yellow
        Write-Host "- Loading 7Zip ..."
        Load-Module "7Zip4Powershell"
        Write-Host "- Extracting ..."
        Expand-7Zip -ArchiveFileName $_ -TargetPath ".."
        Write-Host "- Updating Hash ..."
        Set-Content -Path "$($_.Name).hash" -Value $newhash
        Write-Host "- Done."
    }
}

if ((Test-Path $MPModXml) -and (Test-Path ".\username.txt")) {
    Write-Host "- Restoring Username ..." -ForegroundColor Yellow
    [xml]$xml = Get-Content $MPModXml
    $username = ([string](Get-Content ".\username.txt")).Trim()
    $xml.SettingsBlock.ModSettings.username = $username
    $xml.Save("$pwd\$MPModXML")
    Write-Host "  Username: $username" -ForegroundColor Blue
}


Write-Host "Completed. Please close this window." -ForegroundColor Green
Start-Sleep -Seconds 300