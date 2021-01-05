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
$ModsConfigFile = ".\Config\Config\ModsConfig.xml"

if ((Test-Path $ConfigFile) -and (Test-Path $ModsConfigFile)) {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
}
else {
    Write-Host "ERROR: Critical file(s) missing, please fix this." -ForegroundColor Red
    break
}

$ModsPath = $Config.ModsPath
if ((!$ModsPath) -or (!(Test-Path $ModsPath))) {
    Write-Host "ERROR: Invalid mods path in config." -ForegroundColor Red
}

Write-Host "Loading mod list from: $ModsConfigFile"
$ModList = [System.Collections.ArrayList](([xml](Get-Content $ModsConfigFile)).ModsConfigData.activeMods.li).ToLower()
$ModList.Remove("ludeon.rimworld")              # Core
$ModList.Remove("ludeon.rimworld.royalty")      # Royalty Expansion

Write-Host "Creating temp folder ..."
$TempFolderPath = Join-Path $Env:Temp $(New-Guid); New-Item -Type Directory -Path $TempFolderPath -Force | Out-Null

Write-Host "Synching mod folders to temp ..." -ForegroundColor Yellow
Get-ChildItem -Directory -Path $ModsPath | ForEach-Object {
    $ModInfoFile = Join-Path $_.FullName "About\About.xml"
    if (Test-Path $ModInfoFile) {
        $Package = ([xml](Get-Content $ModInfoFile)).ModMetaData.PackageId
        if ($ModList -contains $Package) {
            Write-Host "- Updating: $($_.Name) ($Package)" -ForegroundColor Blue
            robocopy "$($_.FullName)" "$(Join-Path $TempFolderPath $_.Name)" /Z /J /E /PURGE /R:5 /W:1 /NDL | Out-Null
            $ModList.Remove($Package.ToLower())
        }
    }
}

if ($ModList) {
    Write-Host "ERROR: Some mods missing! Please download the below mods before running this command!" -ForegroundColor Red
    $ModList
    Write-Host "Perhaps the path to your workshop content folder is incorrect?" -ForegroundColor Yellow
}
else {
    Write-Host "Cleaning up mods ..." -ForegroundColor Yellow

    Write-Host "- Removing News folders ..."
    Get-ChildItem $TempFolderPath -Directory -Filter "News" -Depth 2 | Remove-Item -Recurse -Force
    
    Write-Host "- Removing Source folders ..."
    Get-ChildItem $TempFolderPath -Directory -Filter "Source*" -Depth 2 | Remove-Item -Recurse -Force
    
    Write-Host "- Removing .vs/.git folders ..."
    Get-ChildItem $TempFolderPath -Directory -Filter ".vs" -Recurse | Remove-Item -Recurse -Force
    Get-ChildItem $TempFolderPath -Directory -Filter ".git" -Recurse | Remove-Item -Recurse -Force
    
    Write-Host "- Removing Packages folders ..."
    Get-ChildItem $TempFolderPath -Directory -Filter "Packages" -Depth 1 | Remove-Item -Recurse -Force
    
    Write-Host "- Removing other source files ..."
    Get-ChildItem $TempFolderPath -File -Include "*.sln", "*.csproj", "*.cs", ".git*", ".editorconfig", "*.swp" -Recurse | Remove-Item -Force
    
    Write-Host "- Removing other unneeded files ..."
    Get-ChildItem $TempFolderPath -File -Include "LICENSE", "LICENSE*.txt", "LICENSE*.md", "README", "README*.txt", "README*.md", "*.7z" -Recurse | Remove-Item -Force
    Get-ChildItem $TempFolderPath -File -Depth 1 | Where-Object { $_.Name -ne "LoadFolders.xml" } | Remove-Item -Force
    
    
    Write-Host "Synching out of temp ..." -ForegroundColor Yellow
    
    Write-Host "- Copying ..."
    robocopy "$TempFolderPath" ".\Game\Mods" /Z /J /E /PURGE /R:5 /W:1 /NDL | Out-Null
}


Write-Host "- Removing temp folder ..."
Remove-Item $TempFolderPath -Recurse -Force

Write-Host "Removing package file ..." -ForegroundColor Yellow
Get-ChildItem "." -File -Filter "Mods.7z" -Depth 1 | Remove-Item -Force
Write-Host "- Please regenerate package files!" -ForegroundColor Blue

Write-Host "Done! Please close this window." -ForegroundColor Green

Start-Sleep -Seconds 300