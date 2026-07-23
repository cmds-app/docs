# Verify a Pikapods Ghost pod against the crawl manifest of the original site.
# Compares every page path and title, checks all image refs on the pod resolve,
# flags residual storage.ghost.io references, and spot-checks RSS and sitemap.
param(
    [Parameter(Mandatory = $false)][string]$PodUrl,       # e.g. https://mypod.pikapod.net (or the final domain)
    [string]$ManifestPath = "$PSScriptRoot\..\..\tmp\data\myorientations-site\crawl-manifest.json"
)
if (-not $PodUrl) { throw 'PodUrl is required.' }
$ErrorActionPreference = 'Continue'
$pod = $PodUrl.TrimEnd('/')
$m = Get-Content $ManifestPath | ConvertFrom-Json
$old = $m.site.TrimEnd('/')
$paths = $m.pages | ForEach-Object { ([uri]$_).AbsolutePath } | Sort-Object -Unique

function Get-Title($html) { [regex]::Match($html, '<title>([^<]*)</title>').Groups[1].Value.Trim() }

$titleDiffs = @(); $podErrors = @(); $imgRefs = [System.Collections.Generic.HashSet[string]]::new(); $ghostCdnPages = @()
$podHost = ([uri]$pod).Host -replace '\.', '\.'
foreach ($p in $paths) {
    try { $oldHtml = (Invoke-WebRequest "$old$p" -UseBasicParsing).Content } catch { $oldHtml = $null }
    try { $podHtml = (Invoke-WebRequest "$pod$p" -UseBasicParsing).Content }
    catch { $podErrors += "$p ($($_.Exception.Response.StatusCode.value__))"; continue }
    if ($oldHtml) {
        $ot = Get-Title $oldHtml; $pt = Get-Title $podHtml
        if ($ot -ne $pt) { $titleDiffs += "{0}: old='{1}' pod='{2}'" -f $p, $ot, $pt }
    }
    foreach ($mm in [regex]::Matches($podHtml, "(?:https?://$podHost)?/content/images/[^\s`"'<>\\)]+")) {
        $u = ($mm.Value -replace '&amp;', '&') -split '\?' | Select-Object -First 1
        if ($u.StartsWith('/')) { $u = "$pod$u" }
        [void]$imgRefs.Add($u)
    }
    if ($podHtml -match 'storage\.ghost\.io') { $ghostCdnPages += $p }
}
Write-Host "paths checked: $($paths.Count)"
Write-Host "pod fetch errors: $(@($podErrors).Count)"; $podErrors | ForEach-Object { Write-Host "  $_" }
Write-Host "title diffs: $(@($titleDiffs).Count)"; $titleDiffs | ForEach-Object { Write-Host "  $_" }
Write-Host "pages still referencing storage.ghost.io: $(@($ghostCdnPages).Count)"; $ghostCdnPages | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }

$imgFail = @(); $imgOk = 0
foreach ($u in $imgRefs) {
    try { Invoke-WebRequest $u -Method Head -UseBasicParsing | Out-Null; $imgOk++ } catch { $imgFail += $u }
}
Write-Host "image refs on pod pages: $($imgRefs.Count) unique; $imgOk OK, $(@($imgFail).Count) broken"
$imgFail | ForEach-Object { Write-Host "  broken: $_" }

foreach ($extra in '/rss/', '/favicon.ico', '/sitemap.xml') {
    try { $r = Invoke-WebRequest "$pod$extra" -Method Get -UseBasicParsing; Write-Host ("{0} -> {1}" -f $extra, $r.StatusCode) }
    catch { Write-Host ("{0} -> {1}" -f $extra, $_.Exception.Response.StatusCode.value__) }
}
