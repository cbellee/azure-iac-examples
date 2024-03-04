Param (
    [CmdletBinding()]
    [string]$AADTenant = 'kainiindustries.net',
    [string]$PublicDnsZone = 'kainiindustries.net',
    [string]$ApiSvcIp,
    [string]$ApiReadRoleName,
    [string]$ApiWriteRoleName,
    [string]$ApplicationRegistrationId
)

# generate API policy XML documents
Write-Host -Object "Generating APIM policy XML file"
$xml = Get-Content .\api-policy-template.xml     

$xml -replace "{{APP_GWY_FQDN}}", "api.$PublicDnsZone" `
    -replace "{{AUDIENCE_API}}", $ApplicationRegistrationId #$appRegistrations."$Prefix-$ApiName-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$ApiSvcIp" `
    -replace "{{READ_ROLE_NAME}}", $ApiReadRoleName #"$ApiName.Role.Read" `
    -replace "{{WRITE_ROLE_NAME}}", $ApiWriteRoleName #"$ApiName.Role.Write" `
    -replace "{{TENANT_NAME}}", $AADTenant > ./product-api-policy.xml
