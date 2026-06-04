@description('The name of the App Service Plan')
param appServicePlanName string

@description('The name of the Web App')
param webAppName string

@description('The location where resources will be deployed')
param location string

@description('The SKU of the App Service Plan')
param webappSku string = 'B1'

@description('The name of the Azure Storage Account')
param storageAccountName string

@description('The PostgreSQL server hostname')
param dbHost string

@description('The name of the database')
param dbName string = 'restaurant'

@description('The Flask secret key for sessions')
@secure()
param secretKey string

@description('The Login Server URL of the Azure Container Registry')
param acrLoginServer string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: webappSku
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux container app service plan
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${webAppName}:latest'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'STORAGE_CONTAINER_NAME'
          value: 'photos'
        }
        {
          name: 'SECRET_KEY'
          value: secretKey
        }
        {
          name: 'DBHOST'
          value: dbHost
        }
        {
          name: 'DBNAME'
          value: dbName
        }
        {
          name: 'DBUSER'
          value: webAppName
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
      ]
    }
  }
}

output principalId string = webApp.identity.principalId
output name string = webApp.name
