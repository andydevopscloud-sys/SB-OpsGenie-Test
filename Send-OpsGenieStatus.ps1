param (
  [string]$SlackWebhookUrl = 'https://webhook.site/'
)

# 1. Retrieve overall service status
$statusUrl    = 'http://status.opsgenie.com/api/v2/status.json'
try {
  $serviceStatus = (Invoke-RestMethod -Uri $statusUrl -ErrorAction Stop).status.description
} catch {
  Write-Error "Error fetching service status: $_"
  exit 1
}

# 2. Retrieve Recent Incidents
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
# 3.1 Status JASON wrapped into hashtable and serialized two levels deep
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

# 3.4 Slack text output with headings and JSON
$slackText = @"
Overall System Status:

$statusJson

3 Most Recent Incidents:

$incidentsJson
"@.Trim()

# 4. Send to Slack (via Webhook)
# After adding $slackText above
$payload = @{ text = $slackText } | ConvertTo-Json

try {
  Invoke-RestMethod `				# POST HTTP request details 
    -Uri        $SlackWebhookUrl `
    -Method     Post `
    -ContentType 'application/json' `
    -Body       ($payload | ConvertTo-Json)

  Write-Host "Notification sent successfully."
} catch {
  Write-Error "Failed to send to Slack: $_"
  exit 1
}