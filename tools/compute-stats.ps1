$diffFiles = Get-Content changed-files.txt -ErrorAction SilentlyContinue
if (-not $diffFiles) {
    $diffFiles = & git -C C:\base\repo\insite\code diff --name-only release/v26.2..release/v26.3
}

# Normalize to page key (lowercase, drop source/InSite.UI/ prefix and .cs/.vb suffix)
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

# Load unused (non-CMDS) page paths
$unused = @{}
$csv = Import-Csv 'C:\base\repo\cmds-app\platform\tmp\analysis\unused-actions.csv'
foreach ($row in $csv) {
    $u = ($row.ControllerPath -replace '^~/', '').ToLower()
    $unused[$u] = $true
}

# Classify
$cmdsPages = @()
$nonCmdsPages = @()
foreach ($k in $pages.Keys) {
    if ($unused.ContainsKey($k)) { $nonCmdsPages += $k }
    else { $cmdsPages += $k }
}

function Tally($keys, $pages) {
    $total = $keys.Count
    $markup = ($keys | Where-Object { $pages[$_].Markup }).Count
    $codeBehind = ($keys | Where-Object { $pages[$_].CodeBehind }).Count
    $both = ($keys | Where-Object { $pages[$_].Markup -and $pages[$_].CodeBehind }).Count
    return [PSCustomObject]@{Total=$total; Markup=$markup; CodeBehind=$codeBehind; Both=$both}
}

Write-Output "ALL aspx pages modified:"
Tally $pages.Keys $pages | Format-List

Write-Output "CMDS-used pages:"
Tally $cmdsPages $pages | Format-List

Write-Output "Non-CMDS (omitted) pages:"
Tally $nonCmdsPages $pages | Format-List

Write-Output "=== CMDS-used markup-only ==="
$cmdsPages | Where-Object { $pages[$_].Markup -and -not $pages[$_].CodeBehind } | Sort-Object

Write-Output ""
Write-Output "=== CMDS-used code-behind-only ==="
$cmdsPages | Where-Object { -not $pages[$_].Markup -and $pages[$_].CodeBehind } | Sort-Object

Write-Output ""
Write-Output "=== CMDS-used both ==="
$cmdsPages | Where-Object { $pages[$_].Markup -and $pages[$_].CodeBehind } | Sort-Object
