// main.bicep to deploy the simulated storage infra (storage account with queue)

import * as naming from './resourceNames.bicep' 

param storageAccountName string = naming.dataStorageAccountName
param queueName string = naming.queueName
param location string = resourceGroup().location

param resourceTags object = {
  description: 'Storage simulation for deploymentStacks demo'
  project: 'demo-deploymentStacks'
}

// Deploys storage account with a queue 
// (could be anything else like SQL, Servicebus, cosmos,... Just for demo purposes)
module storageAccount '../modules/storage.bicep' = {
  name: uniqueString('rg-data-storacc')
  params: {
    storageAccountName: storageAccountName
    queueName: queueName
    location: location
    resourceTags: resourceTags
  }
}

