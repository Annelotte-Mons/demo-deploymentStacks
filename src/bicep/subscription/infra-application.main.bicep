// Deploys the infra for the application (Logic App Standard with working storage account) 
// including RBAC roles to access the queue on the shared storage account

import * as naming from './resourceNames.bicep'

param appRgName string = naming.appRgName
param dataRgName string = naming.dataRgName

param logicAppName string = naming.logicAppName
param logicAppPlanName string = naming.logicAppPlanName
param logicAppPlanSkuName string = naming.logicAppPlanSkuName

param workspaceName string = naming.workspaceName
param appInsightsName string = naming.appInsightsName

// Storage account to host the queue used by the Logic App
param workingStorageAccountName string = naming.logicAppWorkingStorageAccountName
param dataStorageAccountName string = naming.dataStorageAccountName

param resourceTags object = {
  description: 'Application resources for deploymentStacks demo'
  project: 'demo-deploymentStacks'
}

param location string = 'westeurope'


targetScope = 'subscription'

module appRg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: appRgName
  params: {
    name: appRgName
    location: location
    tags: resourceTags
  }
}

// 1. Deploy Log Analytics workspace + App Insights (linked to the LA workspace)
module workSpaceResourceId 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: uniqueString('rg-laworkspace')
  scope: resourceGroup(appRgName)
  dependsOn: [
    appRg
  ]
  params: {
    name: workspaceName
    location: location
    tags: resourceTags
  }
}

module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: uniqueString('rg-appInsightsDeployment')
  scope: resourceGroup(appRgName)
  dependsOn: [
    appRg
  ]
  params: {
    name: appInsightsName
    location: location
    applicationType: 'web'
    tags: resourceTags
    kind: 'web'
    retentionInDays: 30
    workspaceResourceId: workSpaceResourceId.outputs.resourceId
  }
}

// 2. Deploy Logic App standard (no appSettings)
module logicApp '../modules/logicapp-standard.bicep' = {
  name: uniqueString('rg-logicAppDeployment')
  scope: resourceGroup(appRgName)
  dependsOn: [
    appRg
  ]
  params: {
    logicAppName: logicAppName
    logicAppPlanName: logicAppPlanName
    logicAppPlanSkuName: logicAppPlanSkuName
    workingStorageAccountName: toLower(replace('${logicAppName}stor', '-', ''))
    location: location
    resourceTags: resourceTags
  }
}

// 3. Make sure RBAC to storage queue is set.

// Swap to fix "mistakenly" using the working storage account instead of the shared data storage account
// To showcase the advantage of deployment stacks
var makeMistake = true

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  scope: makeMistake ? resourceGroup(appRgName) : resourceGroup(dataRgName)
  name: makeMistake ? workingStorageAccountName : dataStorageAccountName
}

module roleAssignmentLogicAppQueueStorageDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.0' = {
  name: guid(storageAccount.id, logicAppName, roleAssignmentMappings['Storage Queue Data Contributor'])
  scope: resourceGroup(split(storageAccount.id, '/')[4])
  params: {
    principalId: logicApp.outputs.logicAppSystemAssignedIdentityPrincipalId
    resourceId: storageAccount.id
    roleDefinitionId: roleAssignmentMappings['Storage Queue Data Contributor']
    principalType: 'ServicePrincipal'
    enableTelemetry: false
  }
}

// Helper dict for role assignments
var roleAssignmentMappings = {
  'Storage Queue Data Contributor': '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}
