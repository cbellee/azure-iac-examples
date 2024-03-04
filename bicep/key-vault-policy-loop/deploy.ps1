$location = 'australiaeast'
$rgName = 'kv-cbellee-test-rg'
$accessPoliciesObject = '[{"objectId": "508299b6-04f2-4e49-ac91-31fdb60fe94b","permissions": {"keys": [],"secrets": ["get", "list"],"certificates": ["get", "list"]}},{"objectId": "4b5f5ac2-ff23-4d28-b48c-e67bf555ede8","permissions": {"keys": [],"secrets": ["get", "list"],"certificates": ["get", "list"]}},{"objectId": "0d8ccd31-0654-460e-9b62-372e7ee739b9","permissions": {"keys": [],"secrets": ["get", "list", "set"],"certificates": ["get", "list", "set"]}}]' -replace "`"", "\`""

az group create --name $rgName -l $location

az deployment group create `
    --resource-group $rgName `
    --name 'kv-deployment' `
    --template-file ./main.bicep `
    --parameters location=$location `
    --parameters accessPolicies="$accessPoliciesObject"
    