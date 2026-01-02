param([Parameter(Mandatory)][string]$OutDir)

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $OutDir "GuestUsers_$ts.csv"

$guests = Get-MgUser -All -Filter "userType eq 'Guest'" -Property "displayName,userPrincipalName,createdDateTime,signInActivity"
$guests | Select-Object displayName,userPrincipalName,createdDateTime,
  @{n="lastSignInDateTime";e={$_.SignInActivity.LastSignInDateTime}} |
  Export-Csv -NoTypeInformation -Path $out

Write-Output "Wrote: $out"
