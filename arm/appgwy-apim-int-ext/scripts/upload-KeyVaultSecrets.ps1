Param(
    [string]
    $KeyVaultName,

    [string]
    $CertPassword
)

$cerContentType = 'application/x-pkix'
$secureCertPassword = $CertPassword | ConvertTo-SecureString -AsPlainText -Force

Get-ChildItem $PSScriptRoot/../certs -Recurse -Filter *.pfx -File | 
Foreach-Object {
    if (-not (Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $_.BaseName)) {
        Import-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $_.BaseName -FilePath $_.FullName -Password $secureCertPassword
    }
}

Get-ChildItem $PSScriptRoot/../certs/api.kainiindustries.net -Recurse -Filter *.cer -File | 
Foreach-Object {
    if (-not (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name authcert)) {
        $bytesCert = Get-Content -Path $_.FullName -AsByteStream # powershell core only! otherwise -encoding Byte
        $base64Cert = [System.Convert]::ToBase64String($bytesCert) | ConvertTo-SecureString -AsPlainText -Force
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name authcert -SecretValue $base64Cert -ContentType $cerContentType
    }
}