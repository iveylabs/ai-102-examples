param location string

var unique = uniqueString(resourceGroup().id, subscription().id)

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
    publicNetworkAccess: 'enabled'
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
    resource margiesContainer 'containers@2023-01-01' = {
      name: 'margies-travel'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// Outputs
var searchKey = search.listAdminKeys().primaryKey
output searchName string = search.name
output searchKey string = searchKey
