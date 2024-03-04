accountName='storhns345kh3k4jh53k'
dnsSuffix='dfs.core.windows.net'
fileSystem='test'
fileName='video.mp4'
fileSize=$(stat -c%s "$fileName")
rg='hns-demo-rg'
location='australiaeast'

# create a new storage account
az storage account create \
    --name $name \
    -g $rg \
    --sku Standard_LRS \
    --kind StorageV2 \
    --location $location \
    --https-only true \
    --enable-hierarchical-namespace

# get a SAS token
sas=$(az storage account generate-sas \
    --account-name $accountName \
    --services b \
    --resource-types sco \
    --permissions acdlruw \
    --expiry '2023-11-14T11:49:41Z' \
    --https-only \
    --output tsv)

# create 'filesystem' container
curl -i -X PUT \
    -H "x-ms-version: 2023-08-03" \
    -H "x-ms-date: $(date -u)" \
    -H "Content-Length: 0" \
    "https://$accountName.$dnsSuffix/$fileSystem?resource=filesystem&$sas"

# create empty file
curl -i -X PUT \
    -H "x-ms-version: 2023-08-03" \
    -H "x-ms-date: $(date -u)" \
    -H "Content-Length: 0" \
    -H "Content-Type: video/mp4" \
    "https://$accountName.$dnsSuffix/$fileSystem/$fileName?resource=file&$sas"

# append to file & flush uploaded data
curl -i -X PATCH \
    -H "x-ms-version: 2023-08-03" \
    -H "x-ms-date: $(date -u)" \
    -H "Content-Length: $fileSize" \
    -H "Content-Type: video/mp4" \
    "https://$accountName.$dnsSuffix/$fileSystem/$fileName?action=append&flush=true&position=0&$sas" \
    --data-binary "@video.mp4"
