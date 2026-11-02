<#
.SYNOPSIS
Applies Dell Command | Update BIOS and video/other device updates, allowing a reboot.

.DESCRIPTION
Runs the Dell Command | Update CLI, writes failures to the Application event log,
and returns a status based on whether the CLI could be started. The event source is
created if it does not already exist.
#>
$dcuCliPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

$status = 1
$detection = "winget_detect.ps1"

function Register-MyEventSource {
    param($Source)

    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
        New-EventLog -LogName Application -Source $Source
    }
}

Register-MyEventSource -Source $detection

if (Test-Path -Path $dcuCliPath -PathType Leaf) {
    try {
        Start-Process -FilePath $dcuCliPath -ArgumentList "/applyUpdates -updateType=bios,driver -updateDeviceCategory=video,others -silent -autoSuspendBitLocker=enable -reboot=enable -outputLog=C:\ProgramData\Dell\UpdateReport\DCUupdate.log" -Wait -NoNewWindow
        $status = 0
    }
    catch {
        Write-EventLog -LogName Application -Source $detection -EntryType Error -EventId 101 -Message "Process Failed: $error"
        $status = 1
    }

    Write-Output "Updates complete"
    exit $status
}
else {
    Write-EventLog -LogName Application -Source $detection -EntryType Error -EventId 101 -Message "DCU Not Found"
    exit $status
}
