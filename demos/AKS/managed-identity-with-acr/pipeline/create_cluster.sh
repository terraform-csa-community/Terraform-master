#/bin/bash

export RG_NAME=$1
export ENV=$2
export KEY=$3
export ARM_CLIENT_SECRET=$4

today=`date +"%y%m%d"`
uuid=`uuidgen | sed 's/-//g'`

export PLAN_FILE="aks.$ENV.plan.${today}-${uuid}" 

cd ../src

wget https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip    
unzip terraform_0.13.0_linux_amd64.zip

./terraform init -backend=true -backend-config="access_key=$KEY" -backend-config="key=$ENV.terraform.tfstate"
./terraform plan -out="$PLAN_FILE" -var "resource_group_name=$RG_NAME" -var-file="$ENV.tfvars"
./terraform apply -auto-approve $PLAN_FILE

az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account set -s $ARM_SUBSCRIPTION_ID
az storage copy --source-local-path "./$PLAN_FILE" --destination-account-name $STORAGE_ACCOUNT --destination-container plans