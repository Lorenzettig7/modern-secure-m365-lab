# ------------------------------------------------------------
# Get-MFARegistrationInventory.ps1
# Managed Identity + REST only:
#   Graph Reports -> CSV -> Blob (REST PUT) -> Log Analytics (Data Collector API)
# NO Az.* modules. NO Microsoft.Graph.* modules.
# ------------------------------------------------------------

Write-Output "IDENTITY_ENDPOINT=$($env:IDENTITY_ENDPOINT)"
Write-Output "IDENTITY_HEADER set? $([bool]$env:IDENTITY_HEADER)"
Write-Output "MSI_ENDPOINT=$($env:MSI_ENDPOINT)"
Write-Output "MSI_SECRET set? $([bool]$env:MSI_SECRET)"

$ErrorActionPreference = "Stop"
Write-Output ("PS Version: {0}" -f $PSVersionTable.PSVersion)

# =========================
# Config
# =========================
$storageAccountName = "lorenzettig7storage"
$containerName      = "reports"

# Log Analytics variables (Automation Variables)
$workspaceId = (Get-AutomationVariable -Name "LAW_WORKSPACE_ID").Trim()
$sharedKey   = (Get-AutomationVariable -Name "LAW_SHARED_KEY").Trim()
Write-Output "LAW_WORKSPACE_ID (runbook) = $workspaceId"
Write-Output "LA ingest URI = https://$workspaceId.ods.opinsights.azure.com/api/logs"

# =========================
# IMDS token helper
# =========================
function Get-ManagedIdentityToken {
    param(
        [Parameter(Mandatory)][string]$Resource
    )

    # --- Option A: IDENTITY_ENDPOINT (common in Automation / Functions style) ---
    if ($env:IDENTITY_ENDPOINT -and $env:IDENTITY_HEADER) {
        $uri = "$($env:IDENTITY_ENDPOINT)?api-version=2019-08-01&resource=$([uri]::EscapeDataString($Resource))"
        $headers = @{
            "X-IDENTITY-HEADER" = $env:IDENTITY_HEADER
            "Metadata"          = "true"
        }
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -TimeoutSec 30
        return $resp.access_token
    }

    # --- Option B: MSI_ENDPOINT (older style) ---
    if ($env:MSI_ENDPOINT -and $env:MSI_SECRET) {
        $uri = "$($env:MSI_ENDPOINT)?api-version=2017-09-01&resource=$([uri]::EscapeDataString($Resource))"
        $headers = @{ "Secret" = $env:MSI_SECRET }
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -TimeoutSec 30
        return $resp.access_token
    }

    # --- Option C: VM IMDS fallback (often NOT reachable in Automation) ---
    $tokenUri = "http://169.254.169.254/metadata/identity/oauth2/token" +
                "?api-version=2018-02-01" +
                "&resource=$([uri]::EscapeDataString($Resource))"

    $resp = Invoke-RestMethod -Method GET -Uri $tokenUri -Headers @{ Metadata = "true" } -TimeoutSec 30
    return $resp.access_token
}


# =========================
# Log Analytics helpers (Data Collector API)
# =========================
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

    $hmac = [System.Security.Cryptography.HMACSHA256]::new()
    $hmac.Key = $keyBytes

    $hash        = $hmac.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($hash)

    return "SharedKey ${WorkspaceId}:$encodedHash"
}

function Send-ToLogAnalytics {
    param(
        [Parameter(Mandatory)][string]$LogType,   # becomes ${LogType}_CL
        [Parameter(Mandatory)][hashtable]$Record
    )

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

# =========================
# Main
# =========================
Write-Output ("[{0}] MFA registration inventory runbook starting." -f (Get-Date).ToUniversalTime().ToString("s"))

# ---- 1) Graph call (Reports endpoint) via REST ----
$graphToken   = Get-ManagedIdentityToken -Resource "https://graph.microsoft.com/"

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Accept"        = "application/json"
}

# Start URL
$uri = "https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails?`$top=999"

$all = New-Object System.Collections.Generic.List[object]

while ($uri) {
    $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $graphHeaders -TimeoutSec 60
    if ($resp.value) {
        foreach ($row in $resp.value) { [void]$all.Add($row) }
    }
    $uri = $resp.'@odata.nextLink'
}

$total = $all.Count
$mfaRegisteredCount = ($all | Where-Object { $_.isMfaRegistered -eq $true }).Count
$mfaNotRegistered   = $total - $mfaRegisteredCount

Write-Output ("Graph rows: {0} | MFA registered: {1} | MFA NOT registered: {2}" -f $total, $mfaRegisteredCount, $mfaNotRegistered)

# ---- 2) Write CSV ----
$fileName = "MFA_Registration_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss")
$path     = Join-Path $env:TEMP $fileName

$export = foreach ($r in $all) {
    [pscustomobject]@{
        UserPrincipalName                           = $r.userPrincipalName
        UserDisplayName                             = $r.userDisplayName
        IsMfaRegistered                             = $r.isMfaRegistered
        IsSsprRegistered                            = $r.isSsprRegistered
        IsPasswordlessCapable                       = $r.isPasswordlessCapable
        IsSystemPreferredAuthenticationMethodEnabled = $r.isSystemPreferredAuthenticationMethodEnabled
        MethodsRegistered                            = (($r.methodsRegistered) -join ";")
    }
}

$export | Export-Csv -NoTypeInformation -Path $path
Write-Output "Wrote CSV: $path"

# ---- 3) Upload CSV to Blob via REST (AAD token for Storage) ----
$storageToken = Get-ManagedIdentityToken -Resource "https://storage.azure.com/"

$blobName = Split-Path -Path $path -Leaf
$blobUri  = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"

$utcNow = [DateTime]::UtcNow.ToString("R")
$blobHeaders = @{
    "Authorization"      = "Bearer $storageToken"
    "x-ms-date"          = $utcNow
    "x-ms-version"       = "2020-10-02"
    "x-ms-blob-type"     = "BlockBlob"
    "x-ms-blob-content-type" = "text/csv"
}

Invoke-WebRequest -Method PUT -Uri $blobUri -Headers $blobHeaders -InFile $path -UseBasicParsing | Out-Null

$uploadedUrl = $blobUri
Write-Output "Uploaded to: $uploadedUrl"

# ---- 4) Send summary record to Log Analytics ----
$record = @{
    TimeGenerated     = (Get-Date).ToUniversalTime().ToString("o")
    ReportType        = "MFARegistration"
    TotalUsers        = [int]$total
    MfaRegistered     = [int]$mfaRegisteredCount
    MfaNotRegistered  = [int]$mfaNotRegistered
    BlobUrl           = $uploadedUrl
    Runbook           = "Get-MFARegistrationInventory"
}

Send-ToLogAnalytics -LogType "M365_MFARegistration" -Record $record

Write-Output ("[{0}] MFA registration inventory runbook finished." -f (Get-Date).ToUniversalTime().ToString("s"))
