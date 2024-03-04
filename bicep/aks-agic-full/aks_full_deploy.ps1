
$rgName = 'aks-full-rg'
$location = 'australiaeast'

bicep build ./aks_full.bicep

$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

$deployment = New-AzResourceGroupDeployment `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile ./aks_full.json `
	-WhatIfResultFormat FullResourcePayloads

$deployment