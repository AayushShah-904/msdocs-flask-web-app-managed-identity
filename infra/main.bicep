targetScope = 'resourceGroup'

@description('The Azure region where all resources will be deployed')
param location string = resourceGroup().location

@description('A unique suffix to append to resource names to ensure global uniqueness (lowercase alphanumeric)')
param appNameSuffix string

@description('The PostgreSQL database admin username')
param dbAdminUsername string = 'pgadmin'

@description('The PostgreSQL database admin password')
@secure()
param dbAdminPassword string

@description('The Flask session secret key (defaults to a unique string generated from resource group ID)')
#disable-next-line secure-secrets-in-params
param secretKey string = uniqueString(resourceGroup().id)

// Construct unique resource names based on suffix
var acrName = 'msdocsacr${appNameSuffix}'
var storageAccountName = 'msdocsstorage${appNameSuffix}'
var appServicePlanName = 'msdocs-mi-plan-${appNameSuffix}'
var webAppName = 'msdocs-mi-webapp-${appNameSuffix}'
var postgresServerName = 'msdocs-mi-postgres-${appNameSuffix}'

// 1. Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    acrName: acrName
    location: location
  }
}

// 2. Deploy Azure Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

// 3. Deploy App Service Plan & Web App
// Note: We bypass circular dependency by interpolating the DB host name directly
module app 'modules/app.bicep' = {
  name: 'appDeployment'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    storageAccountName: storageAccountName
    dbHost: '${postgresServerName}.postgres.database.azure.com'
    dbName: 'restaurant'
    secretKey: secretKey
    acrLoginServer: acr.outputs.loginServer
  }
}

// 4. Deploy PostgreSQL Server & database
// Note: We pass the web app's identity object ID to assign it as the database's Microsoft Entra admin
module db 'modules/db.bicep' = {
  name: 'dbDeployment'
  params: {
    postgresServerName: postgresServerName
    location: location
    dbName: 'restaurant'
    adminUsername: dbAdminUsername
    adminPassword: dbAdminPassword
    appIdentityObjectId: app.outputs.principalId
    appName: app.outputs.name
  }
}

// 5. Declare existing resource references for role assignments scope
resource deployedStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource deployedAcr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// 6. Role Assignment: Storage Blob Data Contributor on Storage Account
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deployedStorageAccount.id, webAppName, 'StorageBlobDataContributor')
  scope: deployedStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: app.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// 7. Role Assignment: AcrPull on ACR
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deployedAcr.id, webAppName, 'AcrPull')
  scope: deployedAcr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: app.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

output webAppUrl string = 'https://${webAppName}.azurewebsites.net'
output acrLoginServer string = acr.outputs.loginServer
output storageAccountName string = storageAccountName
output postgresServerName string = postgresServerName
