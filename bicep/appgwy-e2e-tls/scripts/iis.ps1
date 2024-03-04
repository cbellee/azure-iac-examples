param (
    [string]$PfxThumbprint,
    [string]$WebSiteName = "Default Web Site",
    [string]$DomainName = "api.kainiindustries.net"
)

Install-WindowsFeature -name Web-Server -IncludeManagementTools

Import-Module WebAdministration

try {
    $ErrorActionPreference = 'Stop'

    $certificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -eq $PfxThumbprint}
    if ($null -eq $certificate) {
        Write-Error "Unable to find certificate with thumbprint $PfxThumbprint"
        return
    }

    # create https binding
    if (!$(Get-WebBinding -Name $WebSiteName -Port 443 -Protocol "https")) {
        New-WebBinding -Name $WebSiteName -IPAddress "*" -Port 443 -HostHeader $DomainName -Protocol "https"
        (Get-WebBinding -Name $WebSiteName -Port 443 -Protocol "https").AddSslCertificate($certificate.Thumbprint, "my")
    }

    # allow inbound 443 traffic
    if (!$(Get-NetFirewallRule -Name 'Allow-Inbound-HTTPS')) {
        New-NetFirewallRule -Name 'Allow-Inbound-HTTPS' `
            -DisplayName 'Allow-Inbound-HTTPS' `
            -Description 'Allow inbound traffic on port 443 (HTTPS)' `
            -Enabled True `
            -Profile Any `
            -Direction Inbound `
            -Action Allow `
            -LocalPort 443 `
            -Protocol TCP
    }
} catch {
    "Error: $_"
}
