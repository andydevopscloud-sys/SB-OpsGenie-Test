param (
  [string]$SlackWebhookUrl = 'https://webhook.site/'
)

# 1. Retrieve overall service status of OpsGenie using API call
$statusUrl    = 'http://status.opsgenie.com/api/v2/status.json'
try {
  $serviceStatus = (Invoke-RestMethod -Uri $statusUrl -ErrorAction Stop).status.description
} catch {
  Write-Error "Error fetching service status: $_"
  exit 1
}

# 2. Retrieve recent incidents from the OpsGenie API response
$incidentsUrl = 'http://status.opsgenie.com/api/v2/incidents.json'
try {
  $recentIncidents = (Invoke-RestMethod -Uri $incidentsUrl).incidents `
    | Sort-Object {[DateTime]$_.created_at} -Descending `
    | Select-Object -First 3
} catch {
  Write-Error "Error fetching incidents: $_"
  exit 1
}

# 3. Format Output (JSON payload)
#
# 3.1 Status JSON wrapped into hashtable and serialised two levels deep
$statusObj    = @{ status = @{ description = $serviceStatus } }
$statusJson   = $statusObj    | ConvertTo-Json -Depth 2

# 3.2 Build a clean incidents array with fields required 
$incidentItems = $recentIncidents | ForEach-Object {
    [PSCustomObject]@{
        id         = $_.id
        name       = $_.name
        created_at = $_.created_at
        status     = $_.status
    }
}

# 3.3 Wrap three incidents as JSON
$incidentsObj  = @{ incidents = $incidentItems }
$incidentsJson = $incidentsObj | ConvertTo-Json -Depth 2

# 4. Send to Slack (via Webhook)
#
# 4.1 Building Slack message using Block Kit JSON payload & Serialise nested structure into JSON 
$payload = @{
    blocks = @(
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "*Current system status*"
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "```$statusJson```"
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "*Last 3 Incidents*"
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "```$incidentsJson```"
            }
        }
    )
} 

$jsonPayload = $payload | ConvertTo-Json -Depth 6

# 4.2 Send to Slack using an incoming webhook URL in $SlackWebhookUrl
# Prints a concise error, attempts to dump any HTTP response body for deeper diagnostics
try {
    Invoke-RestMethod `
        -Uri        $SlackWebhookUrl `
        -Method     Post `
        -ContentType 'application/json' `
        -Body       $jsonPayload `
        -ErrorAction Stop

    Write-Host "Notification sent successfully."
}
catch {
    Write-Error "Failed to send to Slack: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $body = ($_.Exception.Response.GetResponseStream() | 
                     New-Object System.IO.StreamReader).ReadToEnd()
            if ($body) { Write-Error "Response body: $body" }
        } catch {}
    }
    exit 1
}
