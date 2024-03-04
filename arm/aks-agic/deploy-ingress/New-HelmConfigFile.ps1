param(
    [string]
    $subscriptionId, 

    [string]
    $resourceGroupName, 

    [bool]
    $usePrivateIp = $false,

    [string]
    $applicationGatewayName, 

    [string]
    $applicationGatewayIdentityResourceId, 

    [string]
    $applicationGatewayIdentityClientId, 

    [string]
    $aksApiServerUri
)

@"
verbosityLevel: 5

appgw:
    environment: AZUREPUBLICCLOUD
    subscriptionId: {0}
    resourceGroup: {1}
    name: {2}
    usePrivateIP: {3}

    # Setting appgw.shared to "true" will create an AzureIngressProhibitedTarget CRD.
    # This prohibits AGIC from applying config for any host/path.
    # Use "kubectl get AzureIngressProhibitedTargets" to view and change this.
    shared: false

armAuth:
    type: aadPodIdentity
    identityResourceID: {4}
    identityClientID: {5}

################################################################################
# Specify if the cluster is RBAC enabled or not
rbac:
    enabled: true # true/false

"@ -f $subscriptionId, $resourceGroupName, $applicationGatewayName, $usePrivateIp, $applicationGatewayIdentityResourceId, $applicationGatewayIdentityClientId, $aksApiServerUri | 
Out-File ./deploy-ingress/helm-config.yaml -Encoding ascii -Force
Get-Content ./deploy-ingress/helm-config.yaml
