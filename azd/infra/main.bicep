targetScope = 'subscription'

// For azd deployments
param envName string

// Parameters for which demos you're running
param introDemo bool
param introRGName string
param visionDemo bool
param visionRGName string
param languageDemo bool
param languageRGName string
param openAIDemo bool
param openAIRGName string
param searchDemo bool
param searchRGName string
param docIntelDemo bool
param docIntelRGName string

// General parameters
param defaultLocation string
param tenantId string = subscription().tenantId
@minLength(1)
param myObjectId string
param multiRGName string

// Vision specific parameters
param customVision bool
param visionLocation string

// OpenAI specific parameters
param openAILocation string

// Document Intelligence specific parameters
param docIntelLocation string

// Multi-service account
module multiRG 'Modules/resourcegroup.bicep' = if(introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo) {
  name: 'multiRG${defaultLocation}'
  params: {
    name: multiRGName
    location: defaultLocation
    envName: envName
  }
}
module multiModule 'Modules/multi.bicep' = if(introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo) {
  name: 'multiModule${defaultLocation}'
  params: {
    location: defaultLocation
  }
  dependsOn: [
    multiRG
  ]
  scope: resourceGroup(multiRGName)
}

// Intro resources
// You still need to create an app registration and assign the required permissions on the vault
// The postprovision script should handle this
module introRG 'Modules/resourcegroup.bicep' = if (introDemo) {
  name: 'introRG${defaultLocation}'
  params: {
    name: introRGName
    location: defaultLocation
    envName: envName
  }
}
module introModule 'Modules/intro.bicep' = if (introDemo) {
  name: 'introModule${defaultLocation}'
  params: {
    location: defaultLocation
    tenantId: tenantId
    myObjectId: myObjectId
  }
  dependsOn: [
    introRG
  ]
  scope: resourceGroup(introRGName)
}

// Vision resources
module visionRG 'Modules/resourcegroup.bicep' = if (visionDemo) {
  name: 'visionRG${visionLocation}'
  params: {
    name: visionRGName
    location: visionLocation
    envName: envName
  }
}
module visionModule 'Modules/vision.bicep' = if (visionDemo) {
  name: 'visionModule${visionLocation}'
  params: {
    location: visionLocation
    customVision: customVision
    tenantId: tenantId
    myObjectId: myObjectId
  }
  dependsOn: [
    visionRG
  ]
  scope: resourceGroup(visionRGName)
}

// Language resources
module languageRG 'Modules/resourcegroup.bicep' = if (languageDemo) {
  name: 'languageRG${defaultLocation}'
  params: {
    name: languageRGName
    location: defaultLocation
    envName: envName
  }
}
module languageModule 'Modules/language.bicep' = if (languageDemo) {
  name: 'languageModule${defaultLocation}'
  params: {
    location: defaultLocation
    myObjectId: myObjectId
  }
  dependsOn: [
    languageRG
  ]
  scope: resourceGroup(languageRGName)
}

// OpenAI resources
module openAIRG 'Modules/resourcegroup.bicep' = if (openAIDemo) {
  name: 'openAIRG${openAILocation}'
  params: {
    name: openAIRGName
    location: openAILocation
    envName: envName
  }
}
module openAIModule 'Modules/openai.bicep' = if (openAIDemo) {
  name: 'openAIModule${openAILocation}'
  params: {
    location: openAILocation
    myObjectId: myObjectId
  }
  dependsOn: [
    openAIRG
  ]
  scope: resourceGroup(openAIRGName)
}

// Search resources
module searchRG 'Modules/resourcegroup.bicep' = if (searchDemo) {
  name: 'searchRG${defaultLocation}'
  params: {
    name: searchRGName
    location: defaultLocation
    envName: envName
  }
}
module searchModule 'Modules/search.bicep' = if (searchDemo) {
  name: 'searchModule${defaultLocation}'
  params: {
    location: defaultLocation
    myObjectId: myObjectId
  }
  dependsOn: [
    searchRG
  ]
  scope: resourceGroup(searchRGName)
}

// Documend Intelligence resources
module docIntelRG 'Modules/resourcegroup.bicep' = if (docIntelDemo) {
  name: 'docIntelRG${docIntelLocation}'
  params: {
    name: docIntelRGName
    location: docIntelLocation
    envName: envName
  }
}
module docIntelModule 'Modules/docintel.bicep' = if (docIntelDemo) {
  name: 'docIntelModule${docIntelLocation}'
  params: {
    location: docIntelLocation
    myObjectId: myObjectId
  }
  dependsOn: [
    docIntelRG
  ]
  scope: resourceGroup(docIntelRGName)
}

// Multi-service outputs
output multiEndpoint string = introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo ? multiModule.outputs.endpoint : 'N/A'
output multiKey string = introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo ? multiModule.outputs.key : 'N/A'

// Intro outputs
output introEndpoint string = introDemo ? introModule.outputs.endpoint : 'N/A'
output introKey string = introDemo ? introModule.outputs.key : 'N/A'
output vaultName string = introDemo ? introModule.outputs.vaultName : 'N/A'

// Vision outputs
output visionEndpoint string = visionDemo ? visionModule.outputs.visionEndpoint : 'N/A'
output visionKey string = visionDemo ? visionModule.outputs.visionKey : 'N/A'
output faceEndpoint string = visionDemo ? visionModule.outputs.faceEndpoint : 'N/A'
output faceKey string = visionDemo ? visionModule.outputs.faceKey : 'N/A'

// Language outputs
output speechEndpoint string = languageDemo ? languageModule.outputs.speechEndpoint : 'N/A'
output speechKey string = languageDemo ? languageModule.outputs.speechKey : 'N/A'
output translationEndpoint string = languageDemo ? languageModule.outputs.translationEndpoint : 'N/A'
output translationKey string = languageDemo ? languageModule.outputs.translationKey : 'N/A'
output languageEndpoint string = languageDemo ? languageModule.outputs.languageEndpoint : 'N/A'
output languageKey string = languageDemo ? languageModule.outputs.languageKey : 'N/A'

// OpenAI outputs
output aoaiEndpoint string = openAIDemo ? openAIModule.outputs.aoaiEndpoint : 'N/A'
output aoaiKey string = openAIDemo ? openAIModule.outputs.aoaiKey : 'N/A'

// Search outputs
output searchName string = searchDemo ? searchModule.outputs.searchName : 'N/A'
output searchKey string = searchDemo ? searchModule.outputs.searchKey : 'N/A'

// Doc Intel outputs
output docintelEndpoint string = docIntelDemo ? docIntelModule.outputs.docintelEndpoint : 'N/A'
output docintelKey string = docIntelDemo ? docIntelModule.outputs.docIntelKey : 'N/A'
