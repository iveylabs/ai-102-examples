param location string

var unique = uniqueString(resourceGroup().id, subscription().id, deployment().name)

// Search resource
resource search 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: 'search${unique}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
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
    resource classContainer 'containers@2023-01-01' = {
      name: 'margies-travel'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}
