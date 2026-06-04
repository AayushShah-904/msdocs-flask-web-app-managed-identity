@description('The name of the PostgreSQL Flexible Server')
param postgresServerName string

@description('The location where resources will be deployed')
param location string

@description('The name of the initial database')
param dbName string = 'restaurant'

@description('The database admin login user')
param adminUsername string = 'pgadmin'

@description('The database admin password')
@secure()
param adminPassword string

@description('The principal Object ID of the Web App Managed Identity')
param appIdentityObjectId string

@description('The name of the Web App to use as the database admin display name')
param appName string

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '15'
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
    }
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: postgresServer
  name: dbName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = {
  parent: postgresServer
  name: 'AllowAllAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource postgresEntraAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2023-12-01-preview' = {
  parent: postgresServer
  name: appIdentityObjectId
  properties: {
    principalType: 'ServicePrincipal'
    principalName: appName
    tenantId: subscription().tenantId
  }
  dependsOn: [
    database
    firewallRule
  ]
}

output fqdn string = postgresServer.properties.fullyQualifiedDomainName
