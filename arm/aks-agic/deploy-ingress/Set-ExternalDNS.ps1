param(
    $ResourceGroupName,
    $ZoneName,
    $ARecordName,
    $CNAMERecordName,
    $PublicIpResourceId
)

# create Azure resource record for App Gateway Public IP
if (-not ($rs = Get-AzDnsRecordSet -Name $ARecordName -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -RecordType A -ErrorAction SilentlyContinue)) {
    New-AzDnsRecordSet -Name $ARecordName -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl 3600 -RecordType A -TargetResourceId $PublicIpResourceId
} else {
    Set-AzDnsRecordSet -RecordSet $rs -Overwrite
}

# create alias record for guestbook.kainiindustries.net
$records = @()
$cname = '{0}.{1}' -f $ARecordName, $ZoneName
$records += New-AzDnsRecordConfig -Cname $cname

if (-not ($rs = Get-AzDnsRecordSet -Name $CNAMERecordName -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -RecordType CNAME -ErrorAction SilentlyContinue)) {
    New-AzDnsRecordSet -Name $CNAMERecordName -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl 3600 -RecordType CNAME -DnsRecords $records
} else {
    Set-AzDnsRecordSet -RecordSet $rs -Overwrite
}