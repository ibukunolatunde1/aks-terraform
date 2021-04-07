STRACC=<new-storage-account-name>
RG=<new-resource-group>
LOCATION=westeurope

#Create resource group
az group create \
    --name $RG \
    --location $LOCATION

#Create the storage account
az storage account create \
    --name $STRACC \
    --resource-group $RG \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2

#Get the key
KEY=$(az storage account keys list -g $RG -n $STRACC --query [0].value -o tsv)

#Create a container
CONTAINER=tfstatetf
az storage container create -n $CONTAINER --account-name $STRACC --account-key $KEY


# terraform init
terraform init -backend-config="storage_account_name=$STRACC" -backend-config="container_name=$CONTAINER" -backend-config="access_key=$KEY" -backend-config="key=codelab.microsoft.tfstate"

export TF_VAR_client_id=$appId
export TF_VAR_client_secret=$password

terraform plan -out out.plan

terraform apply out.plan