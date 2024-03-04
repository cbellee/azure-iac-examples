param location string
param identity string
param keyVaultName string
param storageAccountName string
param secret string

resource stor 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource script_resource 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: location
  name: 'addSecretToKeyVault'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azPowerShellVersion: '6.4'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    arguments: '-KeyVaultName ${keyvault.name} -SecretName "my-secret" -Secret ${secret}'
    cleanupPreference: 'OnSuccess'
    containerSettings: {
      containerGroupName: 'test-group'
    }
    scriptContent: '''
      param(
        [string] $SecretName,
        [string] $Secret,
        [string] $KeyVaultName
        )

      try {
        $secureSecret = $Secret | ConvertTo-SecureString -AsPlainText -Force
        $output = Set-AzKeyVaultSecret -Name $SecretName -SecretValue $secureSecret -VaultName $KeyVaultName -Verbose
        Write-Output $output.id
        $DeploymentScriptOutputs = @{}
        $DeploymentScriptOutputs["secretId"] = $output.id
      } catch {

      }
    '''
    storageAccountSettings: {
      storageAccountName: stor.name
      storageAccountKey: listKeys(stor.id, '2021-08-01').keys[0].value
    }
  }
}

output scriptOutput string = script_resource.properties.outputs.secretId
