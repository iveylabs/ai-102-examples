param location string
param myObjectId string

var unique = uniqueString(resourceGroup().id, subscription().id)
var roleDefinitionId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor

// OpenAI resource
resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'aoai${unique}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Storage resources (for RAG)
resource str 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'str${unique}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: true
  }
  resource blobServices 'blobServices@2023-01-01' = {
    name: 'default'
    resource trainingContainer 'containers@2023-01-01' = {
      name: 'rag'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// Set up Storage Blob Data Contributor permissions
module roleAssignment 'roleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: myObjectId
    roleDefinitionId: roleDefinitionId
    resName: str.name
    storageAccount: true
    vault: false
  }
}

// Outputs
var aoaiKey = account.listKeys().key1
output aoaiEndpoint string = account.properties.endpoint
output aoaiKey string = aoaiKey
