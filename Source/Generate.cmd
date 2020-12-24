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

$autoupdatepath = ".."
$distributablename = "autoupdate.zip"

function Load-Module ($m) {
    if (Get-Module | Where-Object { $_.Name -eq $m }) {
        #write-host "Module $m is already imported." -ForegroundColor Green
    }
    else {
        if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $m }) {
            #write-host "Module $m imported." -ForegroundColor Green
            Import-Module $m
        }
        else {
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }) {
                #write-host "Module $m not available - installing." -ForegroundColor Yellow
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

function Build-Package($Archive, $Path, $Exclude = "", $Root = $false, $Force = $false) {
    if (!$Force -and (Test-Path ".\Packages\$Archive")) {
        Write-Host "- Archive exists: Skipped" -ForegroundColor Blue
    }
    else {
        Write-Host "- Loading 7Zip ..."
        Load-Module "7Zip4Powershell"
        Write-Host "- Creating temp folder ..."
        $tempFolderPath = Join-Path $Env:Temp $(New-Guid); New-Item -Type Directory -Path $tempFolderPath -Force | Out-Null
        Write-Host "- Copying ..."
        $Destination = Join-Path $tempFolderPath $(Resolve-Path -Relative $Path)
        robocopy $Path $Destination -XD $Exclude /Z /J /E /R:5 /W:1 /NDL | Out-Null
        Write-Host "- Compressing ..."
        if ($Root) {
            Compress-7Zip -Path $Destination -ArchiveFileName ".\Packages\$Archive"
        }
        else {
            Compress-7Zip -Path $tempFolderPath -ArchiveFileName ".\Packages\$Archive"
        }
        Write-Host "- Clearing temp folder ..."
        Remove-Item $tempFolderPath -Recurse -Force
    }
}

function Clean-ConfigFolder($Path) {
    Write-Host "- Cleaning Up ..."
    $names = @(
        "Prefs.xml",
        "KeyPrefs.xml",
        "Knowledge.xml",
        "ColourPicker.xml",
        "LastPlayedVersion.txt",
        "*DubsMintMinimapMod.xml",
        "*DubsMintMenusMod.xml",
        "*Moody.xml",
        "*ModManager.xml",
        "RimHUD"
    )
    Get-ChildItem -Directory -Path $Path -Recurse | ForEach-Object {
        $object = $_
        $names |Foreach-Object {
            if ($object.Name -like $_) {
                Write-Host "- Removing Folder: $(Resolve-Path -Relative $object.FullName)" -ForegroundColor Blue
                Remove-Item $object.FullName -Recurse -Force
            }
        }
    }
    Get-ChildItem -File -Path $Path -Recurse | ForEach-Object {
        $object = $_
        $names |Foreach-Object {
            if ($object.Name -like $_) {
                Write-Host "- Removing File: $(Resolve-Path -Relative $object.FullName)" -ForegroundColor Blue
                Remove-Item $object.FullName -Force
            }
        }
    }
    Set-Content -Path $(Join-Path $Path "Config\DevModeDisabled") -Value ($null)
}

Write-Host "Processing Config ..." -ForegroundColor Yellow
Clean-ConfigFolder -Path ".\Config"
Build-Package -Archive ".\Config.7z" -Path ".\Config" -Force $true

Write-Host "Processing Game ..." -ForegroundColor Yellow
Build-Package -Archive ".\Game.7z" -Path ".\Game" -Exclude "Mods"

Write-Host "Processing Mods ..." -ForegroundColor Yellow
Build-Package -Archive ".\Mods.7z" -Path ".\Game\Mods"

Write-Host "Processing Scripts ..." -ForegroundColor Yellow
Build-Package -Archive ".\Scripts.7z" -Path ".\Scripts" -Root $true -Force $true

Write-Host "Building distributable zip ..." -ForegroundColor Yellow
$updatejson = ".\Scripts\Updates\update.json"
if (Test-Path $updatejson) {
    $distributablename = [string](Get-Content $updatejson | ConvertFrom-Json).PackInfo -Replace " "
}
Compress-Archive -Path ".\Scripts\*" -DestinationPath ".\$distributablename.zip" -Force

if ($autoupdatepath) {
    Write-Host "Copying packages ..."
    Get-ChildItem -Path ".\Packages" -Filter *.7z | Copy-Item -Destination $autoupdatepath
}

Write-Host "Done! Please close this window." -ForegroundColor Green
Start-Sleep -Seconds 300