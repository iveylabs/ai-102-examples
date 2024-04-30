param location string

var unique = uniqueString(resourceGroup().id, subscription().id, deployment().name)

// OpenAI resource
resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'aoai${unique}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
}

