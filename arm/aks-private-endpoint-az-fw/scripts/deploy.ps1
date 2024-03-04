param(
    [string]
    $location = 'australiaeast',

    [string]
    $prefix = 'aks-private-endpoint-az',

    [string]
    $deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime()),

    [string]
    $containerName = 'nestedtemplates',

    [string]
    $aksVersion = '1.18.8',

    [int]
    $aksNodeCount = 1,

    [int]
    $aksMaxPods = 50,

    [string]
    $aksNodeVMSize = 'Standard_D2s_v3',

    [string]
    $sshPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809",

    [bool]
    $deployGateway = $false,

    [string]
    $vpnGatewaySharedSecret = "M1cr0soft123",

    [string]
    $routerPublicIpAddress = "110.150.38.95",

    [string]
    $routerPrivateAddressSpace = "192.168.88.0/24",

    [string[]]
	$aadAdminGroupObjectIds = @("f6a900e2-df11-43e7-ba3e-22be99d3cede"),
	
	[string]
	$dbPassword = "M1cr0soft123",

    [object]
    $tags = @{
        'environment' = 'dev'
        'app'         = 'testapp'
    }
)

$ProgressPreference = 'SilentlyContinue'

$rgName = "$prefix-rg"

# create resource group
if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# deploy storage account to hold child ARM templates
$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'
$storageDeployment = New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\nestedtemplates\storage.json `
    -ContainerName $containerName `
    -SasTokenExpiry $sasTokenExpiry

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
    -artifactsLocation $storageDeployment.Outputs.storageContainerUri.value `
    -artifactsLocationSasToken $storageDeployment.Outputs.storageAccountSasToken.value `
    -VpnGatewaySharedSecret $vpnGatewaySharedSecret `
    -RouterPublicIpAddress $routerPublicIpAddress `
    -RouterPrivateAddressSpace $routerPrivateAddressSpace `
    -DeployGateway $false `
    -aadAdminGroupObjectIds $aadAdminGroupObjectIds `
    -sshPublicKey $sshPublicKey `
	-tags $tags `
	-dbAdminPassword $dbPassword `
    -Verbose
