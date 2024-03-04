param(
    [string]
    $resourceGroupName
)

$appGwy = $null
$appGwy = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($null -ne $appGwy) {
    Write-Host "##vso[task.setvariable variable=isDeployApplicationGateway]true"
} else {
    Write-Host "##vso[task.setvariable variable=isDeployApplicationGateway]false"
}