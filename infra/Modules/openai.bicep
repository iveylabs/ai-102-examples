param location string
// For azd deployments
param envName string

var unique = uniqueString(resourceGroup().id, deployment().name)

// OpenAI resource
resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${envName}aoai${unique}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

