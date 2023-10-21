#Import-Module MSAL.PS

# Values shown below are randomly generated, but will need to reflect your environment
#Tentant ID and App ID of Service Principal App.
$tentantId = "<tenant id>"
$ScopeUri = "https://api.securitycenter.microsoft.com/.default"
$appId = "<app registration id>"
$thumb = "<thumbprint cert>" #Thumbprint cert in local certstore

$outputJsonPath = "C:\temp\atp.json"
$outputCsvPath = "C:\temp\atp.csv"

#Script to get Azure AD Oauth2 Access Token
$MsalToken = .\atpdata\ATP_Software_Inventory\Auth-Get-AccessToken.ps1 -ScopeUri $ScopeUri -tentantId $tentantId -appId $appId -thumb $thumb

#GET https://api.securitycenter.microsoft.com/api/machines/SoftwareInventoryByMachine?pageSize=5 &sinceTime=2021-11-01T18%3A35%3A49.924Z

#$dateTime = (Get-Date).ToUniversalTime().AddHours(-48).ToString("o")
$url = "https://api.securitycenter.microsoft.com/api/machines/SoftwareInventoryByMachine"

# Set the WebRequest headers
$headers = @{
    'Content-Type' = 'application/json'
    Accept         = 'application/json'
    Authorization  = "Bearer $($MsalToken.AccessToken)"
}
# Send the webrequest and get the results.
$response = Invoke-WebRequest -Method Get -Uri $url -Headers $headers -ErrorAction Stop

# Extract the values from the response.
$values = ($response | ConvertFrom-Json).value | ConvertTo-Json

# Save JSON file
#Out-File -FilePath $outputJsonPath -InputObject $values
# Extract Entries from json values and export to CSV
#($values | ConvertFrom-Json) | Export-CSV $outputCsvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8