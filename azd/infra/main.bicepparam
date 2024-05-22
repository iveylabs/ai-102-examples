// ************************************************************
//            BEFORE RUNNING THE DEMOS
//    Make sure the following resources have been hard deleted:
//    - AI Services resources
//    - Key Vaults
//    - AML Workspaces
// ************************************************************

using 'main.bicep'

// Environment variables from the pre-provision script
param envName = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')
var intro     = readEnvironmentVariable('INTRO_DEMO', 'false')
var vision    = readEnvironmentVariable('VISION_DEMO', 'false')
var language  = readEnvironmentVariable('LANGUAGE_DEMO', 'false')
var openAI    = readEnvironmentVariable('OPENAI_DEMO', 'false')
var search    = readEnvironmentVariable('SEARCH_DEMO', 'false')
var docIntel  = readEnvironmentVariable('DOCINTEL_DEMO', 'false')

// Set true for the demos you're running
param introDemo     = intro == 'true' ? true : false
param visionDemo    = vision == 'true' ? true : false
param languageDemo  = language == 'true' ? true : false
param openAIDemo    = openAI == 'true' ? true : false
param searchDemo    = search == 'true' ? true : false
param docIntelDemo  = docIntel == 'true' ? true : false

// Resource group names
param multiRGName     = readEnvironmentVariable('MULTI_RESOURCE_GROUP', 'multi-rg')
param introRGName     = readEnvironmentVariable('INTRO_RESOURCE_GROUP', 'intro-rg')
param visionRGName    = readEnvironmentVariable('VISION_RESOURCE_GROUP', 'vision-rg') // For the postprovision script
param languageRGName  = readEnvironmentVariable('LANGUAGE_RESOURCE_GROUP', 'language-rg') // For the postprovision script
param openAIRGName    = readEnvironmentVariable('OPENAI_RESOURCE_GROUP', 'openai-rg')
param searchRGName    = readEnvironmentVariable('SEARCH_RESOURCE_GROUP', 'search-rg') // For the postprovision script
param docIntelRGName  = readEnvironmentVariable('DOCINTEL_RESOURCE_GROUP', 'docintel-rg') // For the postprovision script

// General parameters
param defaultLocation = readEnvironmentVariable('DEFAULT_LOCATION', 'uksouth')

param myObjectId = readEnvironmentVariable('YOUR_OBJECT_ID', 'INVALID_OBJECT_ID') // Get your Entra ID user object id

// Vision specific parameters
param customVision = true // Set to false to skip creation of Custom Vision resources
param visionLocation = readEnvironmentVariable('VISION_LOCATION', 'eastus')

// Azure OpenAI specific parameters
param openAILocation = readEnvironmentVariable('AOAI_LOCATION', 'swedencentral')

// Document Intelligence specific parameters
param docIntelLocation = readEnvironmentVariable('DOCINTEL_LOCATION', 'eastus')
