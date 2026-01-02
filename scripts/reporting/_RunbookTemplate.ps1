# scripts/reporting/_RunbookTemplate.ps1
$ErrorActionPreference = "Stop"
Write-Output ("[{0}] Runbook starting." -f (Get-Date).ToString("s"))

# In Azure Automation, use managed identity auth:
Connect-MgGraph -Identity
if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) {
  Select-MgProfile -Name "v1.0"
}

try {
  # TODO: Job logic here
}
catch {
  Write-Error $_
  throw
}
finally {
  Disconnect-MgGraph | Out-Null
  Write-Output ("[{0}] Runbook finished." -f (Get-Date).ToString("s"))
}
