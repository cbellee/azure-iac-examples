param(
    [string]
    $location = 'australiasoutheast',

    [string]
    $prefix = 'aks-slb-vmss-mid',

    [string]
    $rgName = "$prefix-rg",

    [string]
    $spName = "$prefix-sp",

    [string]
    $deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime()),

    [string]
    $containerName = 'templates',

    [string]
    $aksVersion = '1.16.7',

    [int]
    $aksNodeCount = 1,

    [int]
    $aksMaxPods = 50,

    [string]
    $aksNodeVMSize = 'Standard_D2s_v3',

    [object]
    $tags = @{
        'environment' = 'dev'
        'app'         = 'testapp'
    }
)

$ProgressPreference = 'SilentlyContinue'
$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'

# create resource group
if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# start storage account template deployment
$storageDeployment = New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\templates\nested\storage.json `
    -Tags $tags `
    -ContainerName $containerName `
    -SasTokenExpiry $sasTokenExpiry

# upload ARM template files to blob storage account
$sa = Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageDeployment.Outputs.storageAccountName.Value
Get-ChildItem $PSScriptRoot\..\templates\nested -Filter *.json -File | ForEach-Object {
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
    -TemplateFile $PSScriptRoot\..\templates\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\..\templates\azuredeploy.parameters.json `
    -AksNodeCount $aksNodeCount `
    -AksNodeVMSize $aksNodeVMSize `
    -AksVersion $aksVersion `
    -MaxPods $aksMaxPods `
    -StorageUri $storageDeployment.Outputs.storageContainerUri.value `
    -SasToken $storageDeployment.Outputs.storageAccountSasToken.value `
    -Tags $tags `
    -Verbose
