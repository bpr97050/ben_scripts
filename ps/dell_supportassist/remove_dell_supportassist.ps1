function Uninstall-SupportAssistOsRecoveryPlugin {
    $productCode = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -ceq 'Dell SupportAssist OS Recovery Plugin for Dell Update' } |
        Select-Object -ExpandProperty PSChildName

    if ($productCode) {
        $arguments = "/X$productCode /qn REBOOT=REALLYSUPRESS"
        $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        Write-Host 'Uninstalling Dell SupportAssist OS Recovery Plugin for Dell Update'
        $process.ExitCode
    }
    else {
        Write-Host 'SupportAssist OS Recovery Not Found'
        Write-Host '1'
    }
}

function Uninstall-SupportAssist {
    $uninstallString = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -ceq 'Dell SupportAssist' } |
        Select-Object -ExpandProperty UninstallString

    if ($uninstallString) {
        $arguments = $uninstallString.Substring(12) + ' /qn REBOOT=REALLYSUPRESS'
        $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        Write-Host 'Uninstalling Dell SupportAssist'
        $process.ExitCode
    }
    else {
        Write-Host 'SupportAssist Not Found'
        Write-Host '1'
    }
}

Uninstall-SupportAssistOsRecoveryPlugin
Uninstall-SupportAssist

<#
.SYNOPSIS
Uninstalls Dell SupportAssist products when their uninstall entries are present.

.DESCRIPTION
Checks the machine-wide uninstall registry entries for the SupportAssist OS
Recovery plugin and SupportAssist, then runs their uninstall commands.

.NOTES
Adapted from Jeff's answer to "How to uninstall dell support assist with powershell?":
https://stackoverflow.com/a/68180277/16343096
The answer is licensed under CC BY-SA 4.0. This script adapts its uninstall-entry
lookup and MSI invocation for the Dell SupportAssist products listed above.
#>