param(
    [CmdletBinding()]
    [ValidateSet("Start", "Stop")]
    $Action
)

az aks list | ConvertFrom-Json  | ForEach-Object {
    $cluster = $_
    
    switch ($Action) {
        "Start" {       
            if ($cluster.powerState.code -eq 'Stopped') {
                Write-Host "Starting cluster '$($cluster.name)' in resource group '$($cluster.resourceGroup)'"
                az aks start --name $cluster.name --resource-group $cluster.resourceGroup --no-wait 
            } else {
                Write-Host "Cluster '$($cluster.name)' in resource group '$($cluster.resourceGroup)' is already started"
            }
        }
        "Stop" {
            if ($cluster.powerState.code -eq 'Running') {
                Write-Host "Stopping cluster '$($cluster.name)' in resource group '$($cluster.resourceGroup)'"
                az aks stop --name $cluster.name --resource-group $cluster.resourceGroup --no-wait 
            } else {
                Write-Host "Cluster '$($cluster.name)' in resource group '$($cluster.resourceGroup)' is already stopped"
            }
        }
    }
}