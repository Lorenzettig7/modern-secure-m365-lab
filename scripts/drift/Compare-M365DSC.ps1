param(
  [Parameter(Mandatory)]
  [string]$BaselinePath,
  [Parameter(Mandatory)]
  [string]$CurrentPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BaselinePath)) { throw "BaselinePath not found: $BaselinePath" }
if (-not (Test-Path $CurrentPath)) { throw "CurrentPath not found: $CurrentPath" }

Write-Output "[INFO] Comparing DSC exports..."
Write-Output "Baseline: $BaselinePath"
Write-Output "Current : $CurrentPath"

# Simple file-hash diff (portfolio-friendly). You can replace with richer DSC compare later.
$baseFiles = Get-ChildItem -Path $BaselinePath -Recurse -File
$currFiles = Get-ChildItem -Path $CurrentPath -Recurse -File

$baseMap = @{}
foreach ($f in $baseFiles) {
  $rel = $f.FullName.Substring((Resolve-Path $BaselinePath).Path.Length).TrimStart('\\','/')
  $baseMap[$rel] = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
}

$diffs = New-Object System.Collections.Generic.List[object]

foreach ($f in $currFiles) {
  $rel = $f.FullName.Substring((Resolve-Path $CurrentPath).Path.Length).TrimStart('\\','/')
  $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash

  if (-not $baseMap.ContainsKey($rel)) {
    $diffs.Add([pscustomobject]@{ File=$rel; Change="Added" })
    continue
  }

  if ($baseMap[$rel] -ne $hash) {
    $diffs.Add([pscustomobject]@{ File=$rel; Change="Modified" })
  }
}

# Removed files
$currSet = [System.Collections.Generic.HashSet[string]]::new()
foreach ($f in $currFiles) {
  $rel = $f.FullName.Substring((Resolve-Path $CurrentPath).Path.Length).TrimStart('\\','/')
  $currSet.Add($rel) | Out-Null
}

foreach ($rel in $baseMap.Keys) {
  if (-not $currSet.Contains($rel)) {
    $diffs.Add([pscustomobject]@{ File=$rel; Change="Removed" })
  }
}

Write-Output ("[OK] Drift items: {0}" -f $diffs.Count)
$diffs | Sort-Object Change, File | Format-Table -AutoSize | Out-String | Write-Output

# Save a report next to evidence/reports if present
$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$outDir = Join-Path $repo "evidence/reports"
if (Test-Path $outDir) {
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $path = Join-Path $outDir ("DSC_Drift_{0}.csv" -f $ts)
  $diffs | Export-Csv -NoTypeInformation -Path $path
  Write-Output "[OK] Wrote drift report: $path"
}
