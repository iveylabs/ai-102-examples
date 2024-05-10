// ************************************************************
//            BEFORE RUNNING THE DEMOS
//    Make sure the following resources have been hard deleted:
//    - AI Services resources
//    - Key Vaults
//    - AML Workspaces
// ************************************************************

using 'main.bicep'

// For azd deployments
param envName = readEnvironmentVariable('AZURE_ENV_NAME', 'demo')

// Set true for the demos you're running
param introDemo = true
param visionDemo = true
param languageDemo = true
param openAIDemo = true
param searchDemo = true
param docIntelDemo = true

// Resource group names
param multiRGName = 'multi-rg'
param introRGName = 'intro-rg'
param visionRGName = 'vision-rg'
param languageRGName = 'language-rg'
param openAIRGName = 'openai-rg'
param searchRGName = 'search-rg'
param docIntelRGName = 'docintel-rg'

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
