// Deploys the infra for the application (Logic App Standard with working storage account) 
// including RBAC roles to access the queue on the shared storage account


// Helper param
param resourcePrefix string = 'anmo-ds-demo-rg'

param logicAppName string = '${resourcePrefix}-las'
param logicAppPlanName string = '${resourcePrefix}-las-plan'
param logicAppPlanSkuName string = 'WS1'

param workspaceName string = '${resourcePrefix}-law'
param appInsightsName string = '${resourcePrefix}-insights'

// Storage account to host the queue used by the Logic App
param storageAccountName string = toLower(replace('${resourcePrefix}-stor', '-', ''))


param resourceTags object = {
  description: 'Application resources for deploymentStacks demo'
  project: 'demo-deploymentStacks'
}

param location string = resourceGroup().location



// Helper dict for role assignments
var roleAssignmentMappings = {
  'Storage Queue Data Contributor': '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}


// 1. Deploy Log Analytics workspace + App Insights (linked to the LA workspace)
module workSpaceResourceId 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    name: workspaceName
    location: location
    tags: resourceTags
  }
}

module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'appInsightsDeployment'
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
  name: 'logicAppDeployment'
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
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Add queue storage DATA contributor role to the logic app managed identity on the shared storage account
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: 'RoleAssignmentDeployment'
  scope: storageAccount
  properties: {
    roleDefinitionId: roleAssignmentMappings['Storage Queue Data Contributor']
    principalId: logicApp.outputs.logicAppSystemAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

