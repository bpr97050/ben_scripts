<#
.SYNOPSIS
Removes selected .NET runtimes and Intel Graphics Command Center if detected.

.DESCRIPTION
Targets .NET 5.0.17, .NET 7.0.20, ASP.NET Core 7.0.20, and the Intel Graphics
Command Center app package.

.NOTES
Author: Benjamin Praeger (Benjamin.Praeger@uga.edu)
#>
$PackageName = ".NET_Cleanup"
$LogPath = "C:\adminscripts\logs\$(get-date -f yyyy-MM-dd)-CBBackupcheck.log"
$dotnetcore5 = Get-Package | Where-Object { $_.Name -like '*Microsoft .NET * - 5.0.17*' }
$dotnetcore7 = Get-Package | Where-Object { $_.Name -like '*Microsoft .NET * - 7.0.20*' }
$aspdotnetcore7 = Get-Package | Where-Object { $_.Name -like '*Microsoft ASP.NET * 7.0.20*' }

function Write-Log ($msg) {
    $thelog = "C:\adminscripts\logs\$(get-date -f yyyy-MM-dd)-DOTNET_Cleanup.log"
    $now = Get-Date -Format "[yyyy.MM.dd-HH:mm]"
    $message = "$now " + $msg
    $message >> $thelog
}

function Remove-IntelGraphicsCommandCenter {
    Stop-Service -Name igccservice
    Get-AppxPackage -AllUsers -Name "*IntelGraphicsExperience*" | Remove-AppxPackage -AllUsers
    Write-Log
}

function Remove-DotNet5 {
    Start-Process  "C:\ProgramData\Package Cache\{a699b48e-5748-4980-ad92-0b61b1d9d718}\dotnet-runtime-5.0.17-win-x64" -ArgumentList "/uninstall /s" #.NET RunTime 5.0.17 EXE
    Start-Process MsiExec.exe -ArgumentList "/X {5A66E598-37BD-4C8A-A7CB-A71C32ABCD78} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #.NET RunTime 5.0.17
    Start-Process MsiExec.exe -ArgumentList "/X {8BA25391-0BE6-443A-8EBF-86A29BAFC479} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #NET FX Resolver 5.0.17
    Start-Process MsiExec.exe -ArgumentList "/X {E663ED1E-899C-40E8-91D0-8D37B95E3C69} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #.NET Host 5.0.17
    Write-Log
}

function Remove-DotNet7 {
    Start-Process MsiExec.exe -ArgumentList "/X {EE5EB03B-D65C-4991-848E-2C6E024326DB} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #.NET Host 7.0.20
    Start-Process MsiExec.exe -ArgumentList "/X {B0FC828F-678C-4868-9B5B-99639758E6F3} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #NET FX Resolver 7.0.20
    Start-Process MsiExec.exe -ArgumentList "/X {221BB52A-B763-4C9D-AA62-4B0B6C9AAD62} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait #.NET Runtime 7.0.20
    Write-Log
}

function Remove-AspNetCore7 {
    Start-Process  "C:\ProgramData\Package Cache\{6c2f4b5b-86d2-4aff-bf79-d1e73cc20ab3}\AspNetCoreSharedFrameworkBundle-x64" -ArgumentList "/uninstall /s" # ASP.NET 7.0.20 EXE
    Start-Process MsiExec.exe -ArgumentList "/X {BD401329-F877-391C-9E5A-FEB423C5A196} /qn /norestart ALLOWMSIUNINSTALL=1  IGNOREDEPENDENCIES=ALL ALLUSERS=1" -Wait # ASP.NET 7.0.20
    Write-Log
}
# Intel Graphics Command Center may require this, but really that should be removed anyways.
if ((Get-AppPackage -AllUsers).Name -like "*Graphics Command*") {
    Remove-IntelGraphicsCommandCenter
}
if ($dotnetcore5) {
    Remove-DotNet5
}
if ($dotnetcore7) {
    Remove-DotNet7
}
if ($aspdotnetcore7) {
    Remove-AspNetCore7
}
else {
    Write-Log
}
