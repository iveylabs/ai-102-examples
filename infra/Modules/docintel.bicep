param location string
// For azd deployments
param envName string

var unique = uniqueString(resourceGroup().id, deployment().name)

// Document Intelligence resource
resource docIntel 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${envName}dcintl${unique}'
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}
