param([Parameter(Mandatory)][string]$OutDir)

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $OutDir "ConditionalAccessPolicies_$ts.csv"

$policies = Get-MgIdentityConditionalAccessPolicy -All
$policies | Select-Object displayName,state,createdDateTime,modifiedDateTime |
  Export-Csv -NoTypeInformation -Path $out

Write-Output "Wrote: $out"
