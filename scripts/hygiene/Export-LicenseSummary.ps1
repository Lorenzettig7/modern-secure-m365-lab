param([Parameter(Mandatory)][string]$OutDir)

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $OutDir "LicenseSummary_$ts.csv"

$users = Get-MgUser -All -Property "displayName,userPrincipalName,assignedLicenses"
$users | Select-Object displayName,userPrincipalName,
  @{n="assignedLicensesCount";e={($_.AssignedLicenses | Measure-Object).Count}} |
  Export-Csv -NoTypeInformation -Path $out

Write-Output "Wrote: $out"
