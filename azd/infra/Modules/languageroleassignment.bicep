param roleDefinitionId string
param principalId string
param strName string

var roleAssignmentName = guid(principalId, roleDefinitionId, resourceGroup().id)

// Get a reference to the storage account creating via the language module
resource extStr 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: strName
}

// Configure the service principal with the required RBAC role
resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
  scope: extStr
}
