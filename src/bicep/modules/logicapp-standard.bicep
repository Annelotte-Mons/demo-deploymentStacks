// Module to deploy a Logic App Standard with a dedicated App Service Plan + working Storage Account (auth via managed identity)
param logicAppName string
param logicAppPlanName string

@allowed([
  'WS1' 
  'WS2' 
  'WS3' 
])
param logicAppPlanSkuName string
param logicAppPlanSkuCapacity int = 1
param logicAppPlanMaxBurstCount int = 1

param workingStorageAccountName string

param location string
param resourceTags object


@description('Optional dict of resourceIds of user assigned identities to be added to the logicApp (e.g. {"identity1": {}, "identity2": {}})')
param additionalManagedIdentities object = {}



/*
* Logic App Standard resources
*/
module workingStorageAccount 'br/public:avm/res/storage/storage-account:0.20.0' = {
  name: workingStorageAccountName
  params: {
    name: workingStorageAccountName
    location: location
    tags: union(resourceTags, {'hidden-title': 'working storage account'})
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'
  }
}

var userassignedIdentityName = '${logicAppName}-identity'
var userAssignedIdentityResourceId = resourceId(
  'Microsoft.ManagedIdentity/userAssignedIdentities',
  userassignedIdentityName
)

// User assigned identity needed for the logic app to auth to working storage account
module logicAppUserAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: userassignedIdentityName
  params: {
    name: userassignedIdentityName
    location: location
    tags: resourceTags
  }
}

resource logicAppPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: logicAppPlanName
  location: location
  tags: resourceTags
  sku: {
    name: logicAppPlanSkuName
    capacity: logicAppPlanSkuCapacity
  }
  properties: {
    elasticScaleEnabled: true
    maximumElasticWorkerCount: logicAppPlanMaxBurstCount
  }
}

resource logicApp 'Microsoft.Web/sites@2024-11-01' = {
  location: location
  name: logicAppName
  kind: 'functionapp,workflowapp'
  tags: resourceTags
  dependsOn: [
    logicAppUserAssignedIdentity
  ]
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {} // Used to authenticate LA to the working storage account
      ...additionalManagedIdentities
    }
  }
  properties: {
    serverFarmId: logicAppPlan.id
    publicNetworkAccess: 'Enabled'
    outboundVnetRouting: {
      allTraffic: true
      applicationTraffic: true
    }
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      use32BitWorkerProcess: false
      httpLoggingEnabled: true
      functionsRuntimeScaleMonitoringEnabled: true
      preWarmedInstanceCount: 1
      minTlsVersion: '1.2'
      http20Enabled: true
      minimumElasticInstanceCount: 1
    }
  }
}


var rolesToAssignToUserAssignedIdentity = [
  '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Queue Data Contributor
  '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Table Data Contributor
]
// Needed for the Logic App azurewebjobs settings
module roleAssignmentsUserAssignedIdentity 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.0' = [
  for roleId in rolesToAssignToUserAssignedIdentity: {
    name: 'stor-rbac-${roleId}'
    params: {
      principalId: logicAppUserAssignedIdentity.outputs.principalId
      resourceId: workingStorageAccount.outputs.resourceId
      roleDefinitionId: roleId
      principalType: 'ServicePrincipal'
      enableTelemetry: false
    }
  }
]

output logicAppSystemAssignedIdentityPrincipalId string = logicApp.identity.principalId
output logicAppUserAssignedIdentityResourceId string = logicAppUserAssignedIdentity.outputs.resourceId
output logicAppUserAssignedIdentityPrincipalId string = logicAppUserAssignedIdentity.outputs.principalId
output resourceId string = logicApp.id
