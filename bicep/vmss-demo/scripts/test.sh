RG_NAME="vmss-demo-1-rg"

# scale-up to maximum number of instances
echo "GET https://myapp.kainiindustries.net" | ./vegeta -cpus 4 attack -duration=15m -insecure > /dev/null 2>&1

# wait until half of the instances are in the 'Deleting (Running)' state and add load
VMSS_NAME=$(az vmss list --resource-group $RG_NAME --query [].name -o tsv)
NUM_VMSS_INSTACES=$(az vmss list-instances --resource-group $RG_NAME --name $VMSS_NAME | jq '. | length')

if [[ $NUM_VMSS_INSTACES -gt 5 ]] 
then
    echo "GET https://myapp.kainiindustries.net" | ./vegeta -cpus 4 attack -duration=15m -insecure > /dev/null 2>&1
else
    echo "VM scale set only has $NUM_VMSS_INSTACES instance(s)"
fi
