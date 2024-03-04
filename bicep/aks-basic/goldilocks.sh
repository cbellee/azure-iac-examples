
vpas=k get vpa -A -o json | jq .items[].metadata.name -r
namespaces=k get vpa -A -o json | jq .items[].metadata.namespace -r

for vpa in $(k get vpa -A -o json | jq .items[])
do
    #ns=$($vpa | jq .items[].metadata.name -r)
    #echo $ns
    echo $vpa 
    # k describe vpa 
done
