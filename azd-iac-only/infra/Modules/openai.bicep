param location string

var unique = uniqueString(resourceGroup().id, subscription().id)

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

// Outputs
var aoaiKey = account.listKeys().key1
output aoaiEndpoint string = account.properties.endpoint
output aoaiKey string = aoaiKey
