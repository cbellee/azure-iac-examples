param(
    [string]
    $location = 'australiaeast',

    [string]
    $prefix = 'dev-aks-pe-demo',

    [string]
    $deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime()),

    [string]
    $containerName = 'nestedtemplates',

    [string]
    $aksVersion = '1.16.9',

    [int]
    $aksNodeCount = 1,

    [int]
    $aksMaxPods = 50,

    [string]
    $aksNodeVMSize = 'Standard_D2s_v3',

    [string]
    $sshPublicKey,

    [bool]
    $deployGateway = $false,

    [string]
    $vpnGatewaySharedSecret,

    [string]
    $routerPublicIpAddress,

    [string]
    $routerPrivateAddressSpace,

    [string[]]
    $aadAdminGroupObjectIds,

    [object]
    $tags = @{
        'environment' = 'dev'
        'app'         = 'testapp'
    }
)

$ProgressPreference = 'SilentlyContinue'

# create resource group
$rgName = "$prefix-rg"

if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# start storage account template deployment
$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'
$storageDeployment = New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\nestedtemplates\storage.json `
    -ContainerName $containerName `
    -SasTokenExpiry $sasTokenExpiry `
    -Tags $tags

# upload ARM template files to blob storage account
$sa = Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageDeployment.Outputs.storageAccountName.Value
Get-ChildItem $PSScriptRoot\..\nestedtemplates -File | ForEach-Object {
    Set-AzStorageBlobContent `
        -File $_.FullName `
        -Context $sa.Context `
        -Container $containerName `
        -Blob $_.Name `
        -BlobType Block `
        -Force
}

# start ARM template deployment
New-AzResourceGroupDeployment -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\..\azuredeploy.parameters.json `
    -AksNodeCount $aksNodeCount `
    -AksNodeVMSize $aksNodeVMSize `
    -AksVersion $aksVersion `
    -_artifactsLocation $storageDeployment.Outputs.storageContainerUri.value `
    -_artifactsLocationSasToken $($storageDeployment.Outputs.storageAccountSasToken.value | ConvertTo-SecureString -AsplainText -Force) `
    -VpnGatewaySharedSecret $vpnGatewaySharedSecret `
    -RouterPublicIpAddress $routerPublicIpAddress `
    -RouterPrivateAddressSpace $routerPrivateAddressSpace `
    -DeployGateway $false `
    -aadAdminGroupObjectIds $aadAdminGroupObjectIds `
    -sshPublicKey $sshPublicKey `
    -Tags $tags `
    -Verbose
