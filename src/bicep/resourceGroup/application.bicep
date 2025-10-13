// Deploy the LogicApp AppSettings (technical + custom)
// Note: logic app itself is seen as infra, so deployed in infra-application.main.bicep

// Think of it similar to ContainerApp Environment being the infra
// and the ContainerApp itself being the application

import * as naming from './resourceNames.bicep' 

param logicAppName string = naming.logicAppName
param appInsightsName string = naming.appInsightsName
param logicAppWorkingStorageAccountName string = naming.logicAppWorkingStorageAccountName
param logicAppUserAssignedIdentityResourceId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', '${logicAppName}-identity')


param dataStorageAccountName string = naming.dataStorageAccountName
param queueName string = naming.queueName



module logicApp_AppSettings '../modules/logicapp-appsettings.bicep' = {
  name: 'logicAppAppSettingsDeployment'
  params: {
    logicAppName: logicAppName
    appInsightsName: appInsightsName
    logicAppWorkingStorageAccountName: logicAppWorkingStorageAccountName
    logicAppUserAssignedIdentityResourceId: logicAppUserAssignedIdentityResourceId
    appSettings: {
      queueName: queueName
      queueUri: 'https://${dataStorageAccountName}.queue.${az.environment().suffixes.storage}/${queueName}'
    }
  }
}
