$diffFiles = & git -C C:\base\repo\insite\code diff --name-only release/v26.2..release/v26.3

function Get-PageKey($path) {
    $p = $path -replace '^source/InSite\.UI/', '' -replace '\.aspx(\.cs|\.vb)$', '.aspx'
    return $p.ToLower()
}

$aspxChanges = $diffFiles | Where-Object { $_ -match '\.aspx(\.cs|\.vb)?$' }

$pages = @{}
foreach ($f in $aspxChanges) {
    $key = Get-PageKey $f
    if (-not $pages.ContainsKey($key)) { $pages[$key] = @{Markup=$false; CodeBehind=$false} }
    if ($f -match '\.aspx$') { $pages[$key].Markup = $true }
    elseif ($f -match '\.aspx\.(cs|vb)$') { $pages[$key].CodeBehind = $true }
}

Write-Output "=== Markup-only pages (6 expected) ==="
$pages.Keys | Where-Object { $pages[$_].Markup -and -not $pages[$_].CodeBehind } | Sort-Object

Write-Output ""
Write-Output "=== Code-behind only pages (41 expected) ==="
$pages.Keys | Where-Object { -not $pages[$_].Markup -and $pages[$_].CodeBehind } | Sort-Object
