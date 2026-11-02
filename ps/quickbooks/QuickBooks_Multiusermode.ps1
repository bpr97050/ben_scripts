<#
.SYNOPSIS
Sets the current user's QuickBooks Enterprise 24.0 configuration to multi-user mode.

.NOTES
Author: Benjamin Praeger (Benjamin.Praeger@uga.edu)
#>
$currentQbUser = (Get-WmiObject -Class Win32_ComputerSystem |
    Select-Object -ExpandProperty UserName).Split(
    'MYID\',
    [System.StringSplitOptions]::RemoveEmptyEntries
)
$qbwPath = "C:\Users\$currentQbUser\AppData\Local\Intuit\QuickBooks Enterprise Solutions 24.0\QBWUSER.INI"

function Write-Log ($msg) {
    $thelog = "C:\adminscripts\logs\$(get-date -f yyyy-MM-dd)-CBBackupcheck.log"
    $now = Get-Date -Format "[yyyy.MM.dd-HH:mm]"
    $message = "$now " + $msg
    $message >> $thelog
}

function Set-QuickBooksMultiUserMode {
    if ($qbwPath.Count -gt 0) {
        (Get-Content -Path $qbwPath) -replace 'MULTIUSERMODE=N', 'MULTIUSERMODE=Y' |
            Set-Content -Path $qbwPath
        Set-ItemProperty -Path $qbwPath -Name IsReadOnly -Value $true
        Write-Output "Multiusermode has been set"
        exit 0
        Write-Log
    }
    else {
        Write-Output "QuickBooks QBWUSER.INI not found"
        exit 1
        Write-Log
    }
}

Set-QuickBooksMultiUserMode