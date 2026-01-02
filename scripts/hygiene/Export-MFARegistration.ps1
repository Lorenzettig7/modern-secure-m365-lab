param([Parameter(Mandatory)][string]$OutDir)

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $OutDir "MFA_Registration_$ts.csv"

# NOTE: Some tenants require specific permissions to read auth methods.
$users = Get-MgUser -All -Property "displayName,userPrincipalName"
$rows = foreach ($u in $users) {
  $methods = @()
  try { $methods = Get-MgUserAuthenticationMethod -UserId $u.Id -All } catch {}
  [pscustomobject]@{
    DisplayName = $u.DisplayName
    UPN         = $u.UserPrincipalName
    MethodCount = ($methods | Measure-Object).Count
  }
}
$rows | Export-Csv -NoTypeInformation -Path $out
Write-Output "Wrote: $out"
