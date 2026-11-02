<#
.SYNOPSIS
Removes classic Teams components and installs new Teams.

.DESCRIPTION
Cleans up classic Teams installations, machine-wide components, user registry
entries, files, shortcuts, and the Outlook meeting add-in before running the
bundled teamsbootstrapper.exe.

.NOTES
Authors: Benjamin Praeger (Benjamin.Praeger@uga.edu), Florian Salzmann
Forked from https://github.com/FlorianSLZ/scloud/tree/main/Program%20-%20win32/Microsoft%20Teams%20(new)
#>
$PackageName = "MicrosoftTeamsNEW"
$LogPath = "C:\adminscripts\logs\$(get-date -f yyyy-MM-dd)-MS_TEAMS-update.log"

# Record script output in the deployment log.
Start-Transcript -Path $LogPath -Force

# Remove classic Teams installations and related machine-wide components.

function Uninstall-TeamsClassic ($TeamsPath) {
    try {
        $process = Start-Process -FilePath "$TeamsPath\Update.exe" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Uninstall failed with error: $error"
    }
}

# Match standard local user profile SIDs.
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Collect each local profile's SID, registry hive path, and username.
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } | 
    Select  @{name = "SID"; expression = { $_.PSChildName } }, 
        @{name = "UserHive"; expression = { "$($_.ProfileImagePath)\ntuser.dat" } }, 
        @{name = "Username"; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
 
# Find user hives currently loaded in the registry.
$LoadedHives = gci Registry::HKEY_USERS | ? { $_.PSChildname -match $PatternSID } | Select @{name = "SID"; expression = { $_.PSChildName } }

# Identify profile hives that are not currently loaded.
if ($LoadedHives) {
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = 'SID'; expression = { $_.InputObject } }, UserHive, Username
}
else {
    $UnloadedHives = $ProfileList
}

# Load each profile hive that is not already mounted.
foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    if ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
}
Write-Host "Removing Teams Machine-wide Installer"

# Registry entries for 32-bit machine-wide uninstallers.
$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

# Get all subkeys and match the subkey that contains "Teams Machine-Wide Installer" DisplayName.
$MachineWide = Get-ItemProperty -Path $registryPath | Where-Object -Property DisplayName -eq "Teams Machine-Wide Installer"

if ($MachineWide) {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$($MachineWide.PSChildName)"" /qn" -NoNewWindow -Wait
}
else {
    Write-Host "Teams Machine-Wide Installer not found"
}

# Find local profiles and their per-user Teams installation paths.
$AllUsers = Get-ChildItem -Path "$($ENV:SystemDrive)\Users"

# Per-user uninstall registration for classic Teams.
$folderPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams"

$userProfiles = Get-WmiObject Win32_UserProfile

foreach ($profile in $userProfiles) {
    $sid = $profile.SID
    $userFolderPath = "registry::HKEY_USERS\$sid\$folderPath"

    # Check if the folder exists
    if (Test-Path -Path $userFolderPath) {
        # Remove the folder
        Remove-Item -Path $userFolderPath -Recurse -Force
        Write-Host "Removed folder: $userFolderPath"
    } 
    else {
        Write-Host "Folder $userFolderPath does not exist."
    }
}

# Uninstall classic Teams for each profile where it is installed.
foreach ($User in $AllUsers) {
    Write-Host "Processing user: $($User.Name)"

    # Locate installation folder
    $localAppData = "$($ENV:SystemDrive)\Users\$($User.Name)\AppData\Local\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($User.Name)\Microsoft\Teams"

    if (Test-Path "$localAppData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $localAppData
    }
    elseif (Test-Path "$programData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $programData
    }
    else {
        Write-Host "  Teams installation not found for user $($User.Name)"
    }
}

# Remove the Outlook meeting add-in when its MSI registration exists.
$registryPathAddin = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A7AB73A3-CB10-4AA5-9D38-6AEFFBDE4C91}"
if (Test-Path $registryPathAddin) {
    try {
        # Kill Outlook and Teams to remove the add-in
        Get-Process -Name outlook -ErrorAction SilentlyContinue | Stop-Process -Force
        Get-Process -Name ms-teams -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Process "MsiExec.exe" -ArgumentList /x"{A7AB73A3-CB10-4AA5-9D38-6AEFFBDE4C91} /qn ALLUSERS=1" -Wait 
    }
    catch {
        Write-Error "Failed to remove plugin from Outlook. Error: $error"
    }
}

# Paths used to clean up classic Teams files, shortcuts, and add-ins.
$ClassicTeamsPaths = @(
    "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\Teams",
    "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk",
    "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\TeamsMeetingAddin",
    "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Teams",
    "$($ENV:SystemDrive)\Users\*\AppData\Local\SquirrelTemp",
    "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\TeamsMeetingAdd-in",
    "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\TeamsPresenceAddin"
)

Write-Host "Removing old Teams files and directories..."
foreach ($Path in $ClassicTeamsPaths) {
    if (Test-Path $Path) {
        Write-Host "Removing $Path..."
        Remove-Item -Path $Path -Force -Recurse -ErrorAction SilentlyContinue
    }
}
# Unload the profile hive after registry cleanup.
IF ($item.SID -in $UnloadedHives.SID) {
    [gc]::Collect()
    reg unload HKU\$($item.SID) | Out-Null
}

# Install the new Teams package using the bootstrapper beside this script.

Write-Host "Installing new Teams"
$currentDirectory = Split-Path -Parent $PSCommandPath

$exePath = Join-Path -Path $currentDirectory -ChildPath "teamsbootstrapper.exe"

Start-Process -FilePath $exePath -ArgumentList "-p" -NoNewWindow -Wait

# Stop transcript logging
Stop-Transcript
