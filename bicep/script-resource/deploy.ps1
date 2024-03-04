$location = 'australiaeast'
$rgName = 'script-resource-test-rg'

New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'resource-deployment' `
    -ResourceGroupName $rgName `
    -Mode Incremental `
    -TemplateFile ./deploy.bicep `
    -Location $location `
    -SecretValue '1234567890'
