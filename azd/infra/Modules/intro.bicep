param location string
param tenantId string
param myObjectId string

var unique = uniqueString(resourceGroup().id, subscription().id)
var roleDefinitionId = '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator

// Language resource
resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'intro${unique}'
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
  name: 'kv${unique}'
  location: location
  properties: {
    enableRbacAuthorization: true
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

// Vault RBAC assignment
// Set up Storage Blob Data Owner permissions
module roleAssignment 'roleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: myObjectId
    roleDefinitionId: roleDefinitionId
    resName: vault.name
    storageAccount: false
    vault: true
  }
}

// Outputs
var key = account.listKeys().key1
output endpoint string = account.properties.endpoint
output key string = key
output vaultName string = vault.name
