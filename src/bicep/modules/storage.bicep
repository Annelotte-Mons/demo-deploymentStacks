@minLength(3)
@maxLength(24)
@description('Globally unique name for the storage account (lowercase letters and numbers only).')
param storageAccountName string

@description('Optional Azure region override. Defaults to the resource group location if not supplied.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(63)
@description('Name of the queue to create (lowercase letters, numbers, and dash).')
param queueName string

param resourceTags object = {}

module storageAccount 'br/public:avm/res/storage/storage-account:0.27.1' = {
  name: 'storageAccountDeployment'
  params: {
    name: storageAccountName
    location: location
    tags: union(resourceTags, {'hidden-title': 'data simulation'})
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    queueServices: {
      queues: [
        {
          name: queueName
        }
      ]
    }
  }
}

var queueEndpoint = storageAccount.outputs.serviceEndpoints.queue
var normalizedQueueEndpoint = endsWith(queueEndpoint, '/') ? queueEndpoint : '${queueEndpoint}/'

@description('The name of the deployed storage account.')
output storageAccountName string = storageAccount.outputs.name
@description('Primary endpoint for queue service.')
output queueServiceEndpoint string = queueEndpoint
@description('Full URL of the created queue.')
output queueUrl string = '${normalizedQueueEndpoint}${queueName}'
