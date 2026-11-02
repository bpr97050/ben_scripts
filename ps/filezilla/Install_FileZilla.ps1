<#
.SYNOPSIS
Downloads and silently installs the latest 64-bit FileZilla client.

.DESCRIPTION
Reads the FileZilla release page, decodes its embedded download links, then
downloads the x64 installer to C:\adminscripts\Software\FileZilla.
#>

# Require TLS 1.2 for the release-page and installer requests.
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

        $obj = [PSCustomObject]@{
            Name         = "FileZilla"
            Version      = $version
            Architecture = $Platform.Architecture
            Type         = $Platform.Type
            URI          = $URL
        }

        $results += $obj
    }
}

$results
# Select the x64 executable package for installation.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$target = $results | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" }

New-Item -ItemType Directory -Path "C:\adminscripts\Software\FileZilla" -Force
$file = "C:\adminscripts\Software\FileZilla\FileZilla-$version.exe"

Write-Host "Downloading $($target.URI)"
Invoke-WebRequest $target.URI -OutFile $file -Headers @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36"
}

Write-Host "Saved to $file"

# Install FileZilla silently for all users.
$Install = {
    Write-Host "Installing FileZilla $version"
    Start-Process -FilePath $file -ArgumentList "/S /user=all"
}
$Install