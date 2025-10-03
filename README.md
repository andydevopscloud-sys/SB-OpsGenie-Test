# SB-OpsGenie-Test

**On-call alerting system status check.**

You are tasked with retrieving the current system status of on-call alerting system, OpsGenie, via Powershell scripting.

**Case: ** Provide a mechanism to check OpsGenie's current system status and retrieve information on recent incidents. This data will help quickly assess the health of the OpsGenie service and should be shared with the team via Slack.

**Your task is to write a script that performs the following actions: **

1. **Retrieve Overall Service Status:** Fetch the overall service status of OpsGenie. 
2. **Retrieve Recent Incidents:** Obtain the 3 most recent incidents. 
3. **Format Output:**
  •	The script should output text containing the overall service status. 
  •	Then, it should list the 3 incidents in reverse chronological order (most recent first). 
  •	Each incident entry should include its name, the time it was created, and its current status. 

4. **Send to Slack (via Webhook):**
  •	The formatted information should be sent via a webhook to a Slack channel. 
  •	For this exercise, please use https://webhook.site/ as a stand-in for a real Slack webhook endpoint. 
  •	Your script should use the same JSON message format as specified in the Slack API documentation for incoming webhooks. 
  •	The webhook.site URL will be unique to you, but your code should be generic enough to work with any valid Slack webhook URL. 
