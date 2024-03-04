$uri = 'https://api.kainiindustries.net/external/testapi1/test?param1=eet'

$headers = @{
"Ocp-Apim-Subscription-Key"="410957a5167d4c1986db698af9feff08"
"Ocp-Apim-Trace"="true"
}

$response = Invoke-WebRequest -Uri $uri -Headers $headers -Method GET
$response.Content | ConvertFrom-Json