// Deploy the LogicApp AppSettings (technical + custom)
// Note: logic app itself is seen as infra, so deployed in infra-application.main.bicep
// Note 2: Workflow deployment out of scope for this.

// Think of it similar to ContainerApp Environment being the infra
// and the ContainerApp itself being the application


param logicAppName string
param appInsightsName string
param logicAppWorkingStorageAccountName string
param logicAppUserAssignedIdentityResourceId string


// TODO



module logicApp '../modules/logicapp-appsettings.bicep' = {
  name: 'logicAppAppSettingsDeployment'
  params: {
    logicAppName: logicAppName
    appInsightsName: appInsightsName
    logicAppWorkingStorageAccountName: logicAppWorkingStorageAccountName
    logicAppUserAssignedIdentityResourceId: logicAppUserAssignedIdentityResourceId
    appSettings: appSettings
  }
}



