param(
  [string]$OutPath = "./evidence/exports/current"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Microsoft365DSC)) {
  throw "Microsoft365DSC module not found. Install with: Install-Module Microsoft365DSC -Scope CurrentUser"
}

Write-Output "[INFO] Exporting Microsoft365DSC configuration to $OutPath"

Export-M365DSCConfiguration -Components @(
  "AAD","Intune","EXO","SPO","Teams","Purview"
) -Path $OutPath

Write-Output "[OK] Export complete."
