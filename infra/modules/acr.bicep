@description('The name of the Azure Container Registry')
param acrName string

@description('The location where resources will be deployed')
param location string

@description('The pricing tier (SKU) of the container registry')
param acrSku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

output id string = acr.id
output loginServer string = acr.properties.loginServer
