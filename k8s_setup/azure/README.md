# azure/aks env setup for helmfile-infra

## setup 

az cli and manual terraform app registration with portal
- https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
- NOT https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_certificate.html

```
brew install azure-cli
export ARM_CLIENT_ID="9ad2b2a7-0fc3-4af7-b607-8a9457a8f9c8"
export ARM_CLIENT_SECRET="TODO_REAL_SECRET_HERE"
export ARM_SUBSCRIPTION_ID="0a4e7e6a-fc00-4e86-883a-8d99b2e2fcd6"
export ARM_TENANT_ID="538cf6fd-f5d4-4451-8e4a-88c34f2f2619"
export TF_VAR_client_secret="D1yfS]eVMWT:Z2hx:aHTQ:yHe5hkkMq8"
az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
az vm list-sizes --location westus
```

## install
```
terraform init
terrafomr plan
terrafomr apply
az aks get-credentials --resource-group ${var.project} --name ${var.cluster_name}
az aks browse --resource-group bhood-214523 --name azure
```
