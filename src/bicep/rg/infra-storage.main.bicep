// main.bicep to deploy the simulated storage infra (storage account with queue)
param storageAccountName string
param queueName string
param location string = resourceGroup().location

param resourceTags object = {
  description: 'Storage simulation for deploymentStacks demo'
  project: 'demo-deploymentStacks'
}

// Deploys storage account with a queue 
// (could be anything else like SQL, Servicebus, cosmos,... Just for demo purposes)
module storageAccount '../modules/storage.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    storageAccountName: storageAccountName
    queueName: queueName
    location: location
    resourceTags: resourceTags
  }
}
