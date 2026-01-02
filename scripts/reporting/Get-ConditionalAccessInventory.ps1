# =========================
# Get-ConditionalAccessInventory
# Graph -> CSV -> Blob -> Log Analytics summary
# Requires Automation variables:
#   LAW_WORKSPACE_ID  (ex: 384dbc6d-7486-44d5-a725-96818ba29cb9)
#   LAW_SHARED_KEY    (Primary key from Log Analytics workspace)
# =========================

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.SignIns
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Import-Module Az.Accounts
Import-Module Az.Storage

$ErrorActionPreference = "Stop"

# -------- Log Analytics (Data Collector API) helpers --------
function Get-LAAuthSignature {
    param(
        [Parameter(Mandatory)][string]$WorkspaceId,
        [Parameter(Mandatory)][string]$SharedKey,
        [Parameter(Mandatory)][string]$Rfc1123Date,
        [Parameter(Mandatory)][string]$Content
    )

    $method      = "POST"
    $contentType = "application/json"
    $resource    = "/api/logs"

    $contentBytes  = [Text.Encoding]::UTF8.GetBytes($Content)
    $contentLength = $contentBytes.Length

    $stringToHash = "{0}`n{1}`n{2}`nx-ms-date:{3}`n{4}" -f $method, $contentLength, $contentType, $Rfc1123Date, $resource
    $bytesToHash  = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes     = [Convert]::FromBase64String($SharedKey)

    # Robust HMAC creation (works reliably in Automation PS)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $keyBytes

    $hash        = $hmac.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($hash)

    return "SharedKey ${WorkspaceId}:$encodedHash"
}

function Send-ToLogAnalytics {
    param(
        [Parameter(Mandatory)][string]$LogType,
        [Parameter(Mandatory)][hashtable]$Record
    )

    $workspaceId = (Get-AutomationVariable -Name "LAW_WORKSPACE_ID").Trim()
    $sharedKey   = (Get-AutomationVariable -Name "LAW_SHARED_KEY").Trim()

    if ([string]::IsNullOrWhiteSpace($workspaceId)) { throw "LAW_WORKSPACE_ID is empty" }
    if ([string]::IsNullOrWhiteSpace($sharedKey))   { throw "LAW_SHARED_KEY is empty" }

    $rfc1123Date = [DateTime]::UtcNow.ToString("r")
    $resource    = "/api/logs"

    $body = @($Record) | ConvertTo-Json -Depth 10

    $signature = Get-LAAuthSignature -WorkspaceId $workspaceId -SharedKey $sharedKey -Rfc1123Date $rfc1123Date -Content $body
    $uri = "https://{0}.ods.opinsights.azure.com{1}?api-version=2016-04-01" -f $workspaceId, $resource

    $headers = @{
        "Authorization" = $signature
        "Log-Type"      = $LogType
        "x-ms-date"     = $rfc1123Date
    }

    $resp = Invoke-WebRequest -Method POST -Uri $uri -Headers $headers -ContentType "application/json" -Body $body -UseBasicParsing
    Write-Output "Log Analytics ingest OK (Status: $($resp.StatusCode)) -> ${LogType}_CL"
}

# -------- Main --------
Write-Output ("[{0}] CA inventory runbook starting." -f (Get-Date).ToUniversalTime().ToString("s"))

# 1) Query Conditional Access policies via Graph (Managed Identity)
Connect-MgGraph -Identity | Out-Null
if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) { Select-MgProfile -Name "v1.0" }

try {
    $policies = Get-MgIdentityConditionalAccessPolicy -All

    $report = foreach ($p in $policies) {
        [pscustomobject]@{
            DisplayName    = $p.DisplayName
            State          = $p.State
            IncludeUsers   = ($p.Conditions.Users.IncludeUsers   -join ";")
            ExcludeUsers   = ($p.Conditions.Users.ExcludeUsers   -join ";")
            IncludeGroups  = ($p.Conditions.Users.IncludeGroups  -join ";")
            ExcludeGroups  = ($p.Conditions.Users.ExcludeGroups  -join ";")
            IncludeApps    = ($p.Conditions.Applications.IncludeApplications -join ";")
            ExcludeApps    = ($p.Conditions.Applications.ExcludeApplications -join ";")
            ClientAppTypes = ($p.Conditions.ClientAppTypes -join ";")
            GrantControls  = ($p.GrantControls.BuiltInControls -join ";")
        }
    }

    $policyCount = $report.Count

    # 2) Write CSV
    $fileName = "CA_Inventory_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss")
    $path     = Join-Path $env:TEMP $fileName

    $report | Sort-Object DisplayName | Export-Csv -NoTypeInformation -Path $path

    Write-Output "Wrote CSV: $path"
    Write-Output ("Policies: {0}" -f $policyCount)
}
finally {
    Disconnect-MgGraph | Out-Null
}

# 3) Upload CSV to Blob (Managed Identity RBAC)
Connect-AzAccount -Identity | Out-Null

$storageAccountName = "lorenzettig7storage"
$containerName      = "reports"

$ctx      = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
$blobName = Split-Path -Path $path -Leaf

Set-AzStorageBlobContent -File $path -Container $containerName -Blob $blobName -Context $ctx -Force | Out-Null

$uploadedUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"
Write-Output "Uploaded to: $uploadedUrl"

# 4) Send summary event to Log Analytics
$record = @{
    TimeGenerated = (Get-Date).ToUniversalTime().ToString("o")
    ReportType    = "CAInventory"
    Count         = [int]$policyCount
    BlobUrl       = $uploadedUrl
    Runbook       = "Get-ConditionalAccessInventory"
}

Send-ToLogAnalytics -LogType "M365_CAInventory" -Record $record

Write-Output ("[{0}] CA inventory runbook finished." -f (Get-Date).ToUniversalTime().ToString("s"))
