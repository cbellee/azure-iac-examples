using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "PowerShell HTTP trigger function processed a request." 

$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}
if ($name) {
    $status = [HttpStatusCode]::OK 
    $body = "Hello $name"
}
else {
    $status = [HttpStatusCode]::BadRequest 
    $body = "Please pass a name on the query string or in the request body."
}
Push-OutputBinding -Name Response -Value(
    [HttpResponseContext]@{
        StatusCode = $status 
        Body       = $body
    })