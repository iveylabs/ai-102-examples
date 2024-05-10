// ************************************************************
//            BEFORE RUNNING THE DEMOS
//    Make sure the following resources have been hard deleted:
//    - AI Services resources
//    - Key Vaults
//    - AML Workspaces
// ************************************************************

using 'main.bicep'

// Environment name, only used for azd deployments
param envName = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')

// Set true for the demos you're running
param introDemo = true
param visionDemo = false
param languageDemo = false
param openAIDemo = false
param searchDemo = false
param docIntelDemo = false

// Resource group names
param multiRGName = '${envName}multi-rg'
param introRGName = '${envName}intro-rg'
param visionRGName = '${envName}vis-rg'
param languageRGName = '${envName}lang-rg'
param openAIRGName = '${envName}openai-rg'
param searchRGName = '${envName}search-rg'
param docIntelRGName = '${envName}docintel-rg'

// General parameters
param defaultLocation = 'uksouth'

param myObjectId = '' // Get your Entra ID user object id

// Vision specific parameters
param customVision = true // Set to false to skip creation of Custom Vision resources
param visionLocation = 'eastus'

// Azure OpenAI specific parameters
param openAILocation = 'swedencentral'

// Document Intelligence specific parameters
param docIntelLocation = 'eastus'
