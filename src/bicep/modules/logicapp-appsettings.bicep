param logicAppName string
param appInsightsName string
param logicAppWorkingStorageAccountName string
param logicAppUserAssignedIdentityResourceId string

@description('Addtional appsettings to be added to the LogicApp on top of the technical ones.')
param appSettings object = {}


// Technical AppSettings required for the LogicApp
var technical_logicApp_appSettings = {
  APP_KIND: 'workflowApp'
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_INPROC_NET8_ENABLED: 1
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
  AzureWebJobsStorage__accountName: workingStorageAccount.name
  AzureWebJobsStorage__blobServiceUri: 'https://${workingStorageAccount.name}.blob.${az.environment().suffixes.storage}'
  AzureWebJobsStorage__queueServiceUri: 'https://${workingStorageAccount.name}.queue.${az.environment().suffixes.storage}'
  AzureWebJobsStorage__tableServiceUri: 'https://${workingStorageAccount.name}.table.${az.environment().suffixes.storage}'
  AzureWebJobsStorage__credential: 'managedIdentity'
  AzureWebJobsStorage__managedIdentityResourceId: logicAppUserAssignedIdentityResourceId
}

/*
* Link Existing resources (Deployed by Infra)
*/
resource logicApp 'Microsoft.Web/sites@2024-11-01' existing = {
  name: logicAppName
}

resource workingStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: logicAppWorkingStorageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

/*
* Deploy the LogicApp AppSettings
*/
resource logicAppAppSettings 'Microsoft.Web/sites/config@2024-11-01' = {
  name: 'appsettings'
  parent: logicApp
  properties: union(
    technical_logicApp_appSettings,
    appSettings
    )
}
