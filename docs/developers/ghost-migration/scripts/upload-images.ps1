# Upload crawled images to a Pikapods Ghost pod over SFTP, preserving the
# content/images/YYYY/MM structure, then verify each file serves over HTTP.
# Requires the Posh-SSH module (Install-PSResource Posh-SSH -Scope CurrentUser).
param(
    [Parameter(Mandatory = $false)][string]$PodHost,      # e.g. mypod.pikapod.net
    [Parameter(Mandatory = $false)][string]$SftpUser,     # e.g. p12345
    [string]$SftpPassword = $env:PIKAPOD_SFTP_PASSWORD,
    [string]$SourceDir = "$PSScriptRoot\..\..\tmp\data\myorientations-site"
)
if (-not $PodHost -or -not $SftpUser) { throw 'PodHost and SftpUser are required.' }
if (-not $SftpPassword) { throw 'Password required via -SftpPassword or PIKAPOD_SFTP_PASSWORD environment variable.' }
Import-Module Posh-SSH
$SourceDir = (Resolve-Path $SourceDir).Path

$sec = ConvertTo-SecureString $SftpPassword -AsPlainText -Force
$cred = New-Object pscredential($SftpUser, $sec)
$s = New-SFTPSession -ComputerName $PodHost -Port 22 -Credential $cred -AcceptKey

$made = @{}
Get-ChildItem -Recurse -File "$SourceDir\content\images" | ForEach-Object {
    $rel = $_.FullName.Substring("$SourceDir\".Length) -replace '\\', '/'   # content/images/2025/05/x.png
    $rdir = '/' + ($rel -replace '/[^/]+$', '')
    $parts = $rdir.Trim('/') -split '/'
    $acc = ''
    foreach ($p in $parts) {
        $acc = "$acc/$p"
        if (-not $made[$acc] -and -not (Test-SFTPPath -SessionId $s.SessionId -Path $acc)) {
            New-SFTPItem -SessionId $s.SessionId -Path $acc -ItemType Directory | Out-Null
        }
        $made[$acc] = $true
    }
    Set-SFTPItem -SessionId $s.SessionId -Path $_.FullName -Destination $rdir
    Write-Host "uploaded: $rel"
}
Remove-SFTPSession -SessionId $s.SessionId | Out-Null

# Verify over HTTP
$ok = 0; $fail = @()
Get-ChildItem -Recurse -File "$SourceDir\content\images" | ForEach-Object {
    $rel = $_.FullName.Substring("$SourceDir\".Length) -replace '\\', '/'
    try { Invoke-WebRequest "https://$PodHost/$rel" -Method Head -UseBasicParsing | Out-Null; $ok++ }
    catch { $fail += $rel }
}
Write-Host "HTTP verify: $ok OK, $(@($fail).Count) missing"
$fail | ForEach-Object { Write-Host "  404: $_" }
