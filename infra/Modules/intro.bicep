param location string
param tenantId string
param myObjectId string
// For azd deployments
param envName string

var unique = uniqueString(resourceGroup().id, deployment().name)

// Language resource
resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${envName}intro${unique}'
  location: location
  kind: 'TextAnalytics'
  sku: {
    name: 'S'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Key Vault resource with secret
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${envName}kv${unique}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: myObjectId
        permissions: {
          secrets: ['all']
        }
        tenantId: tenantId
      }
    ]
    tenantId: tenantId
  }
  resource secret 'secrets' = {
    name: 'AI-Services-Key'
    properties: {
      value: account.listKeys().key1
    }
  }
}
