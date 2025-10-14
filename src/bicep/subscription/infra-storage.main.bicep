// main.bicep to deploy the simulated storage infra (storage account with queue)

import * as naming from './resourceNames.bicep' 

param rgName string = naming.dataRgName
param storageAccountName string = naming.dataStorageAccountName
param queueName string = naming.queueName
param location string = 'westeurope'

param resourceTags object = {
  description: 'Storage simulation for deploymentStacks demo'
  project: 'demo-deploymentStacks'
}


targetScope = 'subscription'

module rg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: rgName
  params: {
    name: rgName
    location: location
    tags: resourceTags
  }
}


// Deploys storage account with a queue 
// (could be anything else like SQL, Servicebus, cosmos,... Just for demo purposes)
module storageAccount '../modules/storage.bicep' = {
  name: uniqueString('rg-data-storacc')
  scope: resourceGroup(rgName)
  dependsOn: [
    rg
  ]
  params: {
    storageAccountName: storageAccountName
    queueName: queueName
    location: location
    resourceTags: resourceTags
  }
}

