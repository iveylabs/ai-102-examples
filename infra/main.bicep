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
  name: '${envName}multiRG'
  params: {
    name: multiRGName
    location: defaultLocation
    envName: envName
  }
}
module multiModule 'Modules/multi.bicep' = if(introDemo || visionDemo || languageDemo || openAIDemo || searchDemo || docIntelDemo) {
  name: '${envName}multiModule'
  params: {
    location: defaultLocation
    envName: envName
  }
  dependsOn: [
    multiRG
  ]
  scope: resourceGroup(multiRGName)
}

// Intro resources
// You still need to create an app registration and assign the required permissions on the vault
module introRG 'Modules/resourcegroup.bicep' = if (introDemo) {
  name: '${envName}introRG'
  params: {
    name: introRGName
    location: defaultLocation
    envName: envName
  }
}
module introModule 'Modules/intro.bicep' = if (introDemo) {
  name: '${envName}introModule'
  params: {
    location: defaultLocation
    tenantId: tenantId
    myObjectId: myObjectId
    envName: envName
  }
  dependsOn: [
    introRG
  ]
  scope: resourceGroup(introRGName)
}

// Vision resources
module visionRG 'Modules/resourcegroup.bicep' = if (visionDemo) {
  name: '${envName}visionRG'
  params: {
    name: visionRGName
    location: visionLocation
    envName: envName
  }
}
module visionModule 'Modules/vision.bicep' = if (visionDemo) {
  name: '${envName}visionModule'
  params: {
    location: visionLocation
    customVision: customVision
    tenantId: tenantId
    myObjectId: myObjectId
    envName: envName
  }
  dependsOn: [
    visionRG
  ]
  scope: resourceGroup(visionRGName)
}

// Language resources
module languageRG 'Modules/resourcegroup.bicep' = if (languageDemo) {
  name: '${envName}languageRG'
  params: {
    name: languageRGName
    location: defaultLocation
    envName: envName
  }
}
module languageModule 'Modules/language.bicep' = if (languageDemo) {
  name: '${envName}languageModule'
  params: {
    location: defaultLocation
    envName: envName
  }
  dependsOn: [
    languageRG
  ]
  scope: resourceGroup(languageRGName)
}

// OpenAI resources
module openAIRG 'Modules/resourcegroup.bicep' = if (openAIDemo) {
  name: '${envName}openAIRG'
  params: {
    name: openAIRGName
    location: openAILocation
    envName: envName
  }
}
module openAIModule 'Modules/openai.bicep' = if (openAIDemo) {
  name: '${envName}openAIModule'
  params: {
    location: openAILocation
    envName: envName
  }
  dependsOn: [
    openAIRG
  ]
  scope: resourceGroup(openAIRGName)
}

// Search resources
module searchRG 'Modules/resourcegroup.bicep' = if (searchDemo) {
  name: '${envName}searchRG'
  params: {
    name: searchRGName
    location: defaultLocation
    envName: envName
  }
}
module searchModule 'Modules/search.bicep' = if (searchDemo) {
  name: '${envName}searchModule'
  params: {
    location: defaultLocation
    envName: envName
  }
  dependsOn: [
    searchRG
  ]
  scope: resourceGroup(searchRGName)
}

// Documend Intelligence resources
module docIntelRG 'Modules/resourcegroup.bicep' = if (docIntelDemo) {
  name: '${envName}docIntelRG'
  params: {
    name: docIntelRGName
    location: docIntelLocation
    envName: envName
  }
}
module docIntelModule 'Modules/docintel.bicep' = if (docIntelDemo) {
  name: '${envName}docIntelModule'
  params: {
    location: docIntelLocation
    envName: envName
  }
  dependsOn: [
    docIntelRG
  ]
  scope: resourceGroup(docIntelRGName)
}
