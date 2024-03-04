Param(
    [string]
    $ResourceGroupName,

    [string]
    $ZoneName,

    [string]
    $TargetName
)

$records = @()
$records += New-AzDnsRecordConfig -Cname $TargetName

New-AzDnsRecordSet -Name api `
    -ZoneName $ZoneName `
    -ResourceGroupName $ResourceGroupName `
    -Ttl 3600 `
    -RecordType CNAME `
    -DnsRecords $records `
    -Overwrite `
    -Verbose