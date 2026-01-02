# scripts/hygiene/Invoke-HygieneSuite.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # repo root
$reports = Join-Path $root "evidence/reports"
New-Item -ItemType Directory -Force -Path $reports | Out-Null

Write-Output ("[{0}] Hygiene Suite starting..." -f (Get-Date).ToString("s"))

# If running in Azure Automation, you can use Connect-MgGraph -Identity
# Locally: Connect-MgGraph -Scopes "Directory.Read.All","AuditLog.Read.All","Policy.Read.All","UserAuthenticationMethod.Read.All","Group.Read.All"
try {
  if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
    throw "Microsoft Graph PowerShell SDK not found."
  }

  # Try Managed Identity first; if it fails, user can authenticate interactively
  try {
    Connect-MgGraph -Identity | Out-Null
  } catch {
    Connect-MgGraph -Scopes `
      "Directory.Read.All","AuditLog.Read.All","Policy.Read.All","User.Read.All","Group.Read.All","UserAuthenticationMethod.Read.All" | Out-Null
  }
  Select-MgProfile "v1.0"

  & (Join-Path $PSScriptRoot "Export-PrivilegedRoleAssignments.ps1") -OutDir $reports
  & (Join-Path $PSScriptRoot "Export-GuestUsers.ps1") -OutDir $reports
  & (Join-Path $PSScriptRoot "Export-LicenseSummary.ps1") -OutDir $reports
  & (Join-Path $PSScriptRoot "Export-ConditionalAccessPolicies.ps1") -OutDir $reports
  & (Join-Path $PSScriptRoot "Export-MFARegistration.ps1") -OutDir $reports

  Write-Output ("[{0}] Hygiene Suite finished." -f (Get-Date).ToString("s"))
}
finally {
  Disconnect-MgGraph | Out-Null
}
