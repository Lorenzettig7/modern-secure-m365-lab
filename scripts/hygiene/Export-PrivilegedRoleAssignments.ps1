param([Parameter(Mandatory)][string]$OutDir)

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $OutDir "PrivilegedRoles_$ts.csv"

# Directory roles + members (simple proof of least privilege checks)
$roles = Get-MgDirectoryRole -All
$rows = foreach ($r in $roles) {
  $members = Get-MgDirectoryRoleMember -DirectoryRoleId $r.Id -All -ErrorAction SilentlyContinue
  foreach ($m in $members) {
    [pscustomobject]@{
      RoleName   = $r.DisplayName
      MemberId   = $m.Id
      MemberType = $m.AdditionalProperties.'@odata.type'
      Retrieved  = (Get-Date).ToString("s")
    }
  }
}
$rows | Export-Csv -NoTypeInformation -Path $out
Write-Output "Wrote: $out"
