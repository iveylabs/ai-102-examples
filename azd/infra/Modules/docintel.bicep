param location string

var unique = uniqueString(resourceGroup().id, subscription().id)

// Document Intelligence resource
resource docIntel 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'docintel${unique}'
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Storage resources
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
      name: 'customtraining'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// Outputs
var key = docIntel.listKeys().key1
output docintelEndpoint string = docIntel.properties.endpoint
output docIntelKey string = key
