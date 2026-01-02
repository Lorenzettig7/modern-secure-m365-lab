Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Reports
Import-Module Microsoft.Graph.Identity.SignIns
Import-Module Az.Accounts
Import-Module Az.Storage

$ErrorActionPreference = "Stop"

function Get-LAAuthSignature {
    param(
        [Parameter(Mandatory)][string]$WorkspaceId,
        [Parameter(Mandatory)][string]$SharedKey,
        [Parameter(Mandatory)][string]$Rfc1123Date,
        [Parameter(Mandatory)][string]$Content
    )

    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"

    $contentBytes = [Text.Encoding]::UTF8.GetBytes($Content)
    $contentLength = $contentBytes.Length

    $stringToHash = "{0}`n{1}`n{2}`nx-ms-date:{3}`n{4}" -f $method, $contentLength, $contentType, $Rfc1123Date, $resource
    $bytesToHash  = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes     = [Convert]::FromBase64String($SharedKey)

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $keyBytes

    $hash = $hmac.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($hash)

    return "SharedKey ${WorkspaceId}:$encodedHash"
}

function Send-ToLogAnalytics {
    param(
        [Parameter(Mandatory)][string]$LogType,   # shows as ${LogType}_CL
        [Parameter(Mandatory)][hashtable]$Record
    )

    $workspaceId = (Get-AutomationVariable -Name "LAW_WORKSPACE_ID").Trim()
    $sharedKey   = (Get-AutomationVariable -Name "LAW_SHARED_KEY").Trim()

    if ([string]::IsNullOrWhiteSpace($workspaceId)) { throw "LAW_WORKSPACE_ID variable is empty." }
    if ([string]::IsNullOrWhiteSpace($sharedKey))   { throw "LAW_SHARED_KEY variable is empty." }

    $rfc1123Date = [DateTime]::UtcNow.ToString("r")
    $resource = "/api/logs"

    # MUST be an array of records
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

Write-Output ("[{0}] Get-SignInFailures starting" -f (Get-Date).ToString("s"))

# 1) Graph (Managed Identity)
Connect-MgGraph -Identity
if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) { Select-MgProfile -Name "v1.0" }

$report = @()
$failuresCount = 0

try {
    $since  = (Get-Date).ToUniversalTime().AddDays(-7).ToString("o")
    $filter = "createdDateTime ge $since"

    $signins = Get-MgAuditLogSignIn -Filter $filter -All

    $report = foreach ($s in $signins) {
        if ($null -ne $s.Status -and $s.Status.ErrorCode -ne 0) {
            [pscustomobject]@{
                CreatedDateTime         = $s.CreatedDateTime
                UserPrincipalName       = $s.UserPrincipalName
                AppDisplayName          = $s.AppDisplayName
                IPAddress               = $s.IPAddress
                ConditionalAccessStatus = $s.ConditionalAccessStatus
                ErrorCode               = $s.Status.ErrorCode
                FailureReason           = $s.Status.FailureReason
            }
        }
    }

    $failuresCount = ($report | Measure-Object).Count
    Write-Output ("Failures (last 7 days): {0}" -f $failuresCount)

    # 2) Write CSV to temp
    $fileName = "SigninFailures_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss")
    $path = Join-Path $env:TEMP $fileName

    $report | Sort-Object CreatedDateTime -Descending | Export-Csv -NoTypeInformation -Path $path
    Write-Output "Wrote CSV: $path"
}
finally {
    Disconnect-MgGraph | Out-Null
}

# 3) Upload CSV to Storage (Managed Identity)
Connect-AzAccount -Identity | Out-Null

$storageAccountName = "lorenzettig7storage"
$containerName      = "reports"

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
$blobName = Split-Path -Path $path -Leaf

Set-AzStorageBlobContent -File $path -Container $containerName -Blob $blobName -Context $ctx -Force | Out-Null

$uploadedUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"
Write-Output "Uploaded to: $uploadedUrl"

# 4) Send summary to Log Analytics
$record = @{
    TimeGenerated = (Get-Date).ToUniversalTime().ToString("o")
    ReportType    = "SignInFailures"
    Failures      = [int]$failuresCount
    BlobUrl       = $uploadedUrl
    Runbook       = "Get-SignInFailures"
}

Send-ToLogAnalytics -LogType "M365_SignInFailures" -Record $record

Write-Output ("[{0}] Get-SignInFailures finished" -f (Get-Date).ToString("s"))
