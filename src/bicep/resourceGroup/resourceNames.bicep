// Centralized resource naming conventions for the deployment
// Usually this would be something more dynamic, but for demo purposes we keep it simple.

var resourcePrefix string = 'anmo-ds-rg'

@export()
var logicAppName string = '${resourcePrefix}-las'
@export()
var logicAppPlanName string = '${logicAppName}-plan'
@export()
var logicAppPlanSkuName string = 'WS1'
@export()
var logicAppWorkingStorageAccountName string = toLower(replace('${logicAppName}-stor', '-', ''))
@export()
var workspaceName string = '${resourcePrefix}-law'
@export()
var appInsightsName string = '${resourcePrefix}-insights'
@export()
var dataStorageAccountName string = toLower(replace('${resourcePrefix}-data', '-', ''))
@export()
var queueName string = 'mikehue'
