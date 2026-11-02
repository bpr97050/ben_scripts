<#
.SYNOPSIS
Checks the installed FileZilla version against the latest release.

.DESCRIPTION
Reads and decodes the FileZilla release page to determine the latest version.
Returns 0 only when the installed version is current and meets the script's
existing architecture policy.
#>

# Require TLS 1.2 for the release-page request.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ReleaseURL = "https://filezilla-project.org/download.php?show_all=1"

$Platforms = @(
    @{Architecture = 'x86'; Type = 'exe'; Pattern = 'FileZilla_\d+\.\d+\.\d+_win32-setup\.exe' }
    @{Architecture = 'x64'; Type = 'exe'; Pattern = 'FileZilla_\d+\.\d+\.\d+_win64-setup\.exe' }
    @{Architecture = 'x86'; Type = 'zip'; Pattern = 'FileZilla_\d+\.\d+\.\d+_win32\.zip' }
    @{Architecture = 'x64'; Type = 'zip'; Pattern = 'FileZilla_\d+\.\d+\.\d+_win64\.zip' }
)

# Use browser-like request headers for the release page.
$Headers = @{
    "Content-Type" = "text/html; charset=UTF-8"
    "Accept"       = "*/*"
    "User-Agent"   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    "Referer"      = "https://filezilla-project.org/download.php?type=client"
}

Write-Host "Querying FileZilla download page..."

$response = Invoke-WebRequest -Uri $ReleaseURL -Headers $Headers -UseBasicParsing
$content = $response.Content

# Decode values embedded in the release page.
$v1 = [Convert]::FromBase64String(([regex]::Match($content, 'v1="([^"]+)"')).Groups[1].Value)
$v2 = [Convert]::FromBase64String(([regex]::Match($content, 'v2="([^"]+)"')).Groups[1].Value)
$v3 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([regex]::Match($content, 'v3="([^"]+)"')).Groups[1].Value))

$cipherB64 = ([regex]::Match($content, '<div[^>]+id="contentwrapper"[^>]*>(.*?)</div>', 'Singleline')).Groups[1].Value
$cipherBytes = [Convert]::FromBase64String($cipherB64)

$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Mode = "CBC"
$aes.Padding = "PKCS7"
$aes.Key = $v2
$aes.IV = $v1

# Decrypt the encoded markup so the download links can be extracted.
$decryptor = $aes.CreateDecryptor()
$plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
$plaintext = [Text.Encoding]::UTF8.GetString($plainBytes)

# Extract HTTPS links from the decrypted markup.
$links = [regex]::Matches($plaintext, '<a\s+(?:[^>]*?\s+)?href=(["''])(https://.*?)\1', 'IgnoreCase') |
    ForEach-Object { $_.Groups[2].Value }

$results = @()

foreach ($Platform in $Platforms) {
    $URL = $links | Where-Object { $_ -match $Platform.Pattern } | Select-Object -First 1

    if ($URL) {
        $versionMatch = [regex]::Match($URL, 'FileZilla_(\d+\.\d+\.\d+)_')
        $version = $versionMatch.Groups[1].Value
    }
}

# Prefer a 64-bit installation when both install locations exist.
$filezilla_path64 = "C:\Program Files\FileZilla FTP Client\filezilla.exe"
$filezilla_path32 = "C:\Program Files (x86)\FileZilla FTP Client\filezilla.exe"

if (Test-Path -Path $filezilla_path64 -PathType Leaf) {
    $filezilla_version = (Get-Command "C:\Program Files\FileZilla FTP Client\filezilla.exe").Version.ToString(3)
    if ($filezilla_version -lt $version) {
        Write-Output "FileZilla 64 bit is outdated, version $filezilla_version is installed and the latest version is $version"
        exit 1
    }
    elseif ($filezilla_version -eq $version) {
        Write-Output "Filezilla $filezilla_version (64 bit) is already installed, the latest version is $version"
        exit 0 
    }
}

elseif (Test-Path -Path $filezilla_path32 -PathType Leaf) {
    $filezilla_version = (Get-Command "C:\Program Files (x86)\FileZilla FTP Client\filezilla.exe").Version.ToString(3)
    if ($filezilla_version -lt $version) {
        Write-Output "FileZilla is outdated and 32 bit, version $filezilla_version is installed and the latest version is $version"
        exit 1
    }
    elseif ($filezilla_version -eq $version) {
        Write-Output "Filezilla $filezilla_version is already installed, but it's 32 bit"
        exit 1
    }
}

else {
    Write-Output "Filezilla not found, the latest version is $version"
    exit 1
}
