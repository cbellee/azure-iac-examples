param vmssName string
param extensionName string = 'linuxHealthExtension'
param forceUpdateTag int
param protocol string = 'http'
param port int = 80
param requestPath string = '/'

resource healthExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2020-06-01' = {
  name: '${vmssName}/${extensionName}'
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    forceUpdateTag: string(forceUpdateTag)
    type: 'ApplicationHealthLinux'
    typeHandlerVersion: '1.0'
    publisher: 'Microsoft.ManagedServices'
    settings: {
      protocol: protocol
      port: port
      requestPath: requestPath
    }
  }
}
