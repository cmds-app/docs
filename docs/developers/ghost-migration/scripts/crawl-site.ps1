# Crawl a Ghost site's sitemap and download all original /content/images/ files.
# Produces <OutDir>\content\images\YYYY\MM\... (ready for SFTP to a Ghost pod)
# and <OutDir>\crawl-manifest.json (page list + image lists for later verification).
param(
    [string]$SiteUrl = 'https://www.myorientations.com',
    [string]$OutDir  = "$PSScriptRoot\..\..\tmp\data\myorientations-site"
)
$ErrorActionPreference = 'Stop'
$base = $SiteUrl.TrimEnd('/')
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

# 1. Collect page URLs from the Ghost sitemap index
$pages = [System.Collections.Generic.HashSet[string]]::new()
$imageUrls = [System.Collections.Generic.HashSet[string]]::new()

$idxRaw = (Invoke-WebRequest "$base/sitemap.xml" -UseBasicParsing).Content
$idx = [xml]$idxRaw
$subSitemaps = @($idx.sitemapindex.sitemap | ForEach-Object { $_.loc })
if (-not $subSitemaps) { $subSitemaps = @("$base/sitemap.xml") }

foreach ($sm in $subSitemaps) {
    try {
        $subRaw = (Invoke-WebRequest $sm -UseBasicParsing).Content
        $sub = [xml]$subRaw
        foreach ($u in $sub.urlset.url) {
            if ($u.loc) { [void]$pages.Add([string]$u.loc) }
        }
        # Ghost puts feature images in the sitemap (image:loc); these may be
        # storage.ghost.io CDN URLs whose paths embed /c/xx/xx/<uuid>/content/images/
        foreach ($m in ([regex]::Matches($subRaw, '<image:loc>([^<]+)</image:loc>'))) {
            [void]$imageUrls.Add($m.Groups[1].Value)
        }
    } catch { Write-Warning "sitemap fetch failed: $sm : $_" }
}
Write-Host "Pages from sitemap: $($pages.Count)"

# 2. Fetch each page, harvest same-site image refs; note external refs for the manifest
$siteHost = ([uri]$base).Host -replace '\.', '\.'
$imgPattern = "(?:https?://$siteHost)?/content/images/[^\s`"'<>\\)]+"
$externalImgs = [System.Collections.Generic.HashSet[string]]::new()
$fetched = 0
foreach ($p in $pages) {
    try {
        $html = (Invoke-WebRequest $p -UseBasicParsing).Content
        $fetched++
        foreach ($m in [regex]::Matches($html, $imgPattern)) {
            $u = $m.Value -replace '&amp;', '&'
            if ($u.StartsWith('/')) { $u = "$base$u" }
            [void]$imageUrls.Add($u)
        }
        foreach ($m in [regex]::Matches($html, "<img[^>]+src=`"(https?://(?!$siteHost)[^`"]+)`"")) {
            [void]$externalImgs.Add($m.Groups[1].Value)
        }
    } catch { Write-Warning "page fetch failed: $p : $_" }
}
Write-Host "Pages fetched: $fetched; raw image refs: $($imageUrls.Count)"

# 3. Normalize to originals: strip /size/wNNN/ and /format/xxx/ segments, drop query strings.
#    Also collapse storage.ghost.io CDN paths (/c/xx/xx/<uuid>/content/images/...) so every
#    URL maps to a plain content/images/... path.
$originals = [System.Collections.Generic.HashSet[string]]::new()
foreach ($u in $imageUrls) {
    $n = $u -replace '/content/images/size/w\d+(?:h\d+)?/', '/content/images/'
    $n = $n -replace '/content/images/format/[a-z]+/', '/content/images/'
    $n = ($n -split '\?')[0]
    [void]$originals.Add($n)
}
Write-Host "Unique original images: $($originals.Count)"

# 4. Download preserving content/images/ structure (CDN prefix collapsed)
$ok = 0; $failed = @()
foreach ($u in ($originals | Sort-Object)) {
    if ($u -notmatch '/content/images/') { continue }
    $rel = ($u -replace '^.*?/content/images/', 'content\images\') -replace '/', '\'
    $rel = [uri]::UnescapeDataString($rel)
    $dest = Join-Path $OutDir $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    if (Test-Path $dest) { $ok++; continue }
    try {
        Invoke-WebRequest $u -OutFile $dest -UseBasicParsing
        $ok++
    } catch {
        $failed += $u
        Write-Warning "download failed: $u"
    }
}

# 5. Manifest + summary
$manifest = [pscustomobject]@{
    site            = $base
    pages           = @($pages | Sort-Object)
    images_local    = @($originals | Sort-Object)
    images_failed   = @($failed)
    images_external = @($externalImgs | Sort-Object)
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $OutDir 'crawl-manifest.json')

$size = (Get-ChildItem -Recurse -File (Join-Path $OutDir 'content') | Measure-Object -Sum Length).Sum
Write-Host ("DONE: {0}/{1} images downloaded, {2:N1} MB, {3} external image refs, output: {4}" -f $ok, $originals.Count, ($size/1MB), $externalImgs.Count, $OutDir)
if ($failed) { Write-Host 'FAILED:'; $failed | ForEach-Object { Write-Host "  $_" } }
Write-Host 'Review images_external in the manifest: storage.ghost.io entries die when Ghost(Pro) is cancelled.'
