param customVision bool
param location string
param tenantId string
param myObjectId string

var unique = uniqueString(resourceGroup().id, deployment().name)

// Custom vision resources (if you want to do a brief demo)
resource customTraining 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (customVision) {
  name: 'train${unique}'
  location: location
  kind: 'CustomVision.Training'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}
resource customPrediction 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (customVision) {
  name: 'predict${unique}'
  location: location
  kind: 'CustomVision.Prediction'
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
    resource classContainer 'containers@2023-01-01' = {
      name: 'classification'
      properties: {
        publicAccess: 'Blob'
      }
    }
    resource detectionContainer 'containers@2023-01-01' = {
      name: 'detection'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// Azure Machine Learning resources
resource appInsightsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'appinsights${unique}'
  location: location
}
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appinsights${unique}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: appInsightsWorkspace.id
  }
}
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv${unique}'
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
}
resource amlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: 'aml${unique}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    applicationInsights: appInsights.id
    keyVault: vault.id
    storageAccount: str.id
  }
}

// Computer vision resource
resource computerVision 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'vision${unique}'
  location: location
  kind: 'ComputerVision'
  sku: {
    name: 'S1'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Face resource
resource face 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'face${unique}'
  location: location
  kind: 'Face'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}
