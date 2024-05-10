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
  name: 'multiRG'
  params: {
    name: multiRGName
    location: defaultLocation
    envName: envName
  }
}
module multiModule 'Modules/multi.bicep' = if(introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo) {
  name: 'multiModule'
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
module introRG 'Modules/resourcegroup.bicep' = if (introDemo) {
  name: 'introRG'
  params: {
    name: introRGName
    location: defaultLocation
    envName: envName
  }
}
module introModule 'Modules/intro.bicep' = if (introDemo) {
  name: 'introModule'
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
  name: 'visionRG'
  params: {
    name: visionRGName
    location: visionLocation
    envName: envName
  }
}
module visionModule 'Modules/vision.bicep' = if (visionDemo) {
  name: 'visionModule'
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
  name: 'languageRG'
  params: {
    name: languageRGName
    location: defaultLocation
    envName: envName
  }
}
module languageModule 'Modules/language.bicep' = if (languageDemo) {
  name: 'languageModule'
  params: {
    location: defaultLocation
  }
  dependsOn: [
    languageRG
  ]
  scope: resourceGroup(languageRGName)
}

// OpenAI resources
module openAIRG 'Modules/resourcegroup.bicep' = if (openAIDemo) {
  name: 'openAIRG'
  params: {
    name: openAIRGName
    location: openAILocation
    envName: envName
  }
}
module openAIModule 'Modules/openai.bicep' = if (openAIDemo) {
  name: 'openAIModule'
  params: {
    location: openAILocation
  }
  dependsOn: [
    openAIRG
  ]
  scope: resourceGroup(openAIRGName)
}

// Search resources
module searchRG 'Modules/resourcegroup.bicep' = if (searchDemo) {
  name: 'searchRG'
  params: {
    name: searchRGName
    location: defaultLocation
    envName: envName
  }
}
module searchModule 'Modules/search.bicep' = if (searchDemo) {
  name: 'searchModule'
  params: {
    location: defaultLocation
  }
  dependsOn: [
    searchRG
  ]
  scope: resourceGroup(searchRGName)
}

// Documend Intelligence resources
module docIntelRG 'Modules/resourcegroup.bicep' = if (docIntelDemo) {
  name: 'docIntelRG'
  params: {
    name: docIntelRGName
    location: docIntelLocation
    envName: envName
  }
}
module docIntelModule 'Modules/docintel.bicep' = if (docIntelDemo) {
  name: 'docIntelModule'
  params: {
    location: docIntelLocation
  }
  dependsOn: [
    docIntelRG
  ]
  scope: resourceGroup(docIntelRGName)
}
