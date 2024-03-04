$domain = 'kainiindustries.net'
$financeUserName = "apim_finance_user@$domain" # (asf&sfewefwHH1)
$marketingUserName = "apim_marketing_user@$domain" # (asf&sfewefwHH1)


$rgName = 'dev-appgwy-apim-aks-rg'
$apimName = 'api-mgmt-25go45oxoiwxo'

Get-AzRoleDefinition -Name "API Management Service Reader Role" | ConvertTo-Json | Out-File ".\APIMProductAdminCustomRole.json"

$apimContext = New-AzApiManagementContext -ResourceGroupName $rgName -ServiceName $apimName
$financeProduct = Get-AzApiManagementProduct -Context $apimContext -Title 'Finance'
$marketingProduct = Get-AzApiManagementProduct -Context $apimContext -Title 'Marketing'

$financeCustomRole = Get-Content ./APIMProductAdminCustomRole.json | ConvertFrom-Json
$financeCustomRole.Name = "Finance Custom APIM Role"
$financeCustomRole.Id = (New-Guid).Guid
$financeCustomRole.AssignableScopes = @()
$financeCustomRole.AssignableScopes += $financeProduct.id
$financeCustomRole | ConvertTo-Json | Out-File ./financeProductCustomRole.json

$marketingCustomRole = Get-Content ./APIMProductAdminCustomRole.json | ConvertFrom-Json
$marketingCustomRole.Name = "Marketing Custom APIM Role"
$marketingCustomRole.Id = (New-Guid).Guid
$marketingCustomRole.AssignableScopes = @()
$marketingCustomRole.AssignableScopes += $marketingProduct.id
$marketingCustomRole | ConvertTo-Json | Out-File ./marketingProductCustomRole.json

$financeCustomRoleId = New-AzRoleDefinition  -InputFile  ./financeProductCustomRole.json | Select-Object -ExpandProperty Id
$marketingCustomRoleId = New-AzRoleDefinition  -InputFile  ./marketingProductCustomRole.json | Select-Object -ExpandProperty Id

$financeRole = Get-AzRoleDefinition -Id $financeCustomRoleId
$marketingRole = Get-AzRoleDefinition -Id $marketingCustomRoleId

$financeUser = Get-AzADUser -UserPrincipalName $financeUserName 
$marketingUser = Get-AzADUser -UserPrincipalName $marketingUserName

New-AzRoleAssignment -ObjectId $financeUser.Id -RoleDefinitionName "Reader" -ResourceName $apimName -ResourceType Microsoft.ApiManagement/service -ResourceGroupName $rgName
New-AzRoleAssignment -ObjectId $marketingUser.Id -RoleDefinitionName "Reader" -ResourceName $apimName -ResourceType Microsoft.ApiManagement/service -ResourceGroupName $rgName

New-AzRoleAssignment -SignInName $financeUserName -RoleDefinitionName $financeRole.Name -Scope $financeProduct.Id
New-AzRoleAssignment -SignInName $marketingUserName -RoleDefinitionName $marketingRole.Name -Scope $marketingProduct.Id

Get-AzRoleAssignment -SignInName $financeUserName
Get-AzRoleAssignment -SignInName $marketingUserName