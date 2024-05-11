param location string

var unique = uniqueString(resourceGroup().id, subscription().id)

// Multi-service account resource
resource multi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'multi${unique}'
  location: location
  kind: 'CognitiveServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
var key = multi.listKeys().key1
output endpoint string = multi.properties.endpoint
output key string = key
