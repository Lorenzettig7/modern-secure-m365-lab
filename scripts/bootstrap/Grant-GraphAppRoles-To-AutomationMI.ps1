param(
  [Parameter(Mandatory)]
  [string]$AutomationAccountName
)

# 1) Connect to Graph with an admin account interactively
Connect-MgGraph -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All","Directory.Read.All"
if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) {
  Select-MgProfile -Name "v1.0"
}


# 2) Find the Automation Account's managed identity service principal
# The enterprise app display name is usually the Automation Account name
$miSp = Get-MgServicePrincipal -Filter "displayName eq '$AutomationAccountName'"
if (-not $miSp) { throw "Managed Identity SP not found for $AutomationAccountName" }

# 3) Microsoft Graph service principal (well-known appId)
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# 4) Choose Graph app roles (application permissions) for your reporting jobs
$roleNames = @(
  "Directory.Read.All",
  "AuditLog.Read.All",
  "Policy.Read.All",
  "User.Read.All",
  "Group.Read.All",
  "DeviceManagementConfiguration.Read.All",
  "DeviceManagementManagedDevices.Read.All",
  "SecurityEvents.Read.All"
)

foreach ($roleName in $roleNames) {
  $appRole = $graphSp.AppRoles | Where-Object { $_.Value -eq $roleName -and $_.AllowedMemberTypes -contains "Application" }
  if (-not $appRole) { Write-Warning "Role not found: $roleName"; continue }

  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $miSp.Id `
    -PrincipalId $miSp.Id `
    -ResourceId $graphSp.Id `
    -AppRoleId $appRole.Id

  Write-Host "Assigned: $roleName"
}

Write-Host "Done. Now verify in Entra admin center -> Enterprise Applications -> $AutomationAccountName -> Permissions"
