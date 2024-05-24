Write-Host "IMPORTANT! `nIf you previously deployed the Vision demo, you must delete the soft-deleted AML Workspace to avoid conflicts." -ForegroundColor Magenta
Write-Host "Ensure that any relevant soft-deleted AML Workspaces have been permanently deleted before continuing. `nazd down does NOT permanently delete AML Workspaces." -ForegroundColor Magenta
Read-Host "Press ENTER to continue..."

Write-Host "Running pre-provision script..."
# Get object ID of the current user if the env var is not already set
if (-not $env:YOUR_OBJECT_ID) {
       $UserObjectId = az ad signed-in-user show --query id -o tsv
       if(-not $UserObjectId) {
              Write-Host "Unable to obtain your Entra ID user object ID." -ForegroundColor Red
              $UserObjectId = Read-Host "Please enter your Object ID and press ENTER"
       }
       else {
              $CorrectObjectId = Read-Host "Is this your Object ID? $UserObjectId (y/n)"
              if ($CorrectObjectId -eq 'n') {
                     $UserObjectId = Read-Host "Please enter your Object ID and press ENTER"
              }
       }
       azd env set YOUR_OBJECT_ID $UserObjectId
}

# Set the resource group name for the multi-service account (always deployed)
$MultiResourceGroup = "multi-${env:AZURE_ENV_NAME}-rg"
azd env set MULTI_RESOURCE_GROUP $MultiResourceGroup

$ProvisionAllDemos = Read-Host "Provision all demos? (y/n)"
if ($ProvisionAllDemos -eq 'y') {
       # Ensure the DEFAULT_LOCATION environment variable is set
       if (-not $env:DEFAULT_LOCATION) {
              $defaultLocation = Read-Host "Please enter the default location for your resources"
              azd env set DEFAULT_LOCATION $defaultLocation
       }

       # Intro
       azd env set INTRO_DEMO "true"
       if (-not $env:INTRO_RESOURCE_GROUP) {
              # Ensure the INTRO_RESOURCE_GROUP environment variable is set
              $IntroResourceGroup = "intro-${env:AZURE_ENV_NAME}-rg"
              azd env set INTRO_RESOURCE_GROUP $IntroResourceGroup
       }

       # Vision
       azd env set VISION_DEMO "true"
       if (-not $env:VISION_RESOURCE_GROUP) {
              # Ensure the VISION_RESOURCE_GROUP environment variable is set
              $VisionResourceGroup = "vision-${env:AZURE_ENV_NAME}-rg"
              azd env set VISION_RESOURCE_GROUP $VisionResourceGroup
              
              # Ensure the VISION_LOCATION environment variable is set
              if (-not $env:VISION_LOCATION) {
                     $visionLocation = Read-Host "Please enter the location for your Vision resources"
                     azd env set VISION_LOCATION $visionLocation
              }

       }

       # Language
       azd env set LANGUAGE_DEMO "true"
       # Ensure the LANGUAGE_RESOURCE_GROUP environment variable is set
       if (-not $env:LANGUAGE_RESOURCE_GROUP) {
              $LanguageResourceGroup = "language-${env:AZURE_ENV_NAME}-rg"
              azd env set LANGUAGE_RESOURCE_GROUP $LanguageResourceGroup
       }

       # OpenAI
       azd env set OPENAI_DEMO "true"
       if (-not $env:OPENAI_RESOURCE_GROUP) {
              # Ensure the OPENAI_RESOURCE_GROUP environment variable is set
              $OpenAIResourceGroup = "aoai-${env:AZURE_ENV_NAME}-rg"
              azd env set OPENAI_RESOURCE_GROUP $OpenAIResourceGroup
              
              # Ensure the AOAI_LOCATION environment variable is set
              if (-not $env:AOAI_LOCATION) {
                     $aoaiLocation = Read-Host "Please enter the location for your Azure OpenAI resources"
                     azd env set AOAI_LOCATION $aoaiLocation
              }
       }

       # Search
       azd env set SEARCH_DEMO "true"
       # Ensure the SEARCH_RESOURCE_GROUP environment variable is set
       if (-not $env:SEARCH_RESOURCE_GROUP) {
              $SearchResourceGroup = "search-${env:AZURE_ENV_NAME}-rg"
              azd env set SEARCH_RESOURCE_GROUP $SearchResourceGroup
       }
       # Doc Intel
       azd env set DOCINTEL_DEMO "true"
       # Ensure the DOCINTEL_RESOURCE_GROUP environment variable is set
       if (-not $env:DOCINTEL_RESOURCE_GROUP) {
              $DocIntelResourceGroup = "docintel-${env:AZURE_ENV_NAME}-rg"
              azd env set DOCINTEL_RESOURCE_GROUP $DocIntelResourceGroup

              # Ensure the DOCINTEL_LOCATION environment variable is set
              if (-not $env:DOCINTEL_LOCATION) {
                     $docIntelLocation = Read-Host "Please enter the location for your Document Intelligence resources"
                     azd env set DOCINTEL_LOCATION $docIntelLocation
              }
       }
}
else {
       # Ensure the DEFAULT_LOCATION environment variable is set
       $defaultLocation = Read-Host "Please enter the default location for your resources"
       azd env set DEFAULT_LOCATION $defaultLocation

       # Ensure the INTRO_DEMO environment variable is set
       if (-not $env:INTRO_DEMO) {
              $IntroDemo = Read-Host "Provision Intro Demo? (y/n)"
              if ($IntroDemo -eq 'y') {
                     azd env set INTRO_DEMO "true"
                     if (-not $env:INTRO_RESOURCE_GROUP) {
                            # Ensure the INTRO_RESOURCE_GROUP environment variable is set
                            $IntroResourceGroup = "intro-${env:AZURE_ENV_NAME}-rg"
                            azd env set INTRO_RESOURCE_GROUP $IntroResourceGroup
                     }
              }
              else {
                     azd env set INTRO_DEMO "false"
              }
       }

       # Ensure the VISION_DEMO environment variable is set
       if (-not $env:VISION_DEMO) {
              $VisionDemo = Read-Host "Provision Vision Demo? (y/n)"
              if ($VisionDemo -eq 'y') {
                     azd env set VISION_DEMO "true"
                     if (-not $env:VISION_RESOURCE_GROUP) {
                            # Ensure the VISION_RESOURCE_GROUP environment variable is set
                            $VisionResourceGroup = "vision-${env:AZURE_ENV_NAME}-rg"
                            azd env set VISION_RESOURCE_GROUP $VisionResourceGroup

                            # Ensure the VISION_LOCATION environment variable is set
                            if (-not $env:VISION_LOCATION) {
                                   $visionLocation = Read-Host "Please enter the location for your Vision resources"
                                   azd env set VISION_LOCATION $visionLocation
                            }
                     }
              }
              else {
                     azd env set VISION_DEMO "false"
              }
       }

       # Ensure the LANGUAGE_DEMO environment variable is set
       if (-not $env:LANGUAGE_DEMO) {
              $LanguageDemo = Read-Host "Provision Language Demo? (y/n)"
              if ($LanguageDemo -eq 'y') {
                     azd env set LANGUAGE_DEMO "true"
                     # Ensure the LANGUAGE_RESOURCE_GROUP environment variable is set
                     if (-not $env:LANGUAGE_RESOURCE_GROUP) {
                            $LanguageResourceGroup = "language-${env:AZURE_ENV_NAME}-rg"
                            azd env set LANGUAGE_RESOURCE_GROUP $LanguageResourceGroup
                     }
              }
              else {
                     azd env set LANGUAGE_DEMO "false"
              }
       }

       # Ensure the OPENAI_DEMO environment variable is set
       if (-not $env:OPENAI_DEMO) {
              $OpenAIDemo = Read-Host "Provision Azure OpenAI Demo? (y/n)"
              if ($OpenAIDemo -eq 'y') {
                     azd env set OPENAI_DEMO "true"
                     if (-not $env:OPENAI_RESOURCE_GROUP) {
                            # Ensure the OPENAI_RESOURCE_GROUP environment variable is set
                            $OpenAIResourceGroup = "aoai-${env:AZURE_ENV_NAME}-rg"
                            azd env set OPENAI_RESOURCE_GROUP $OpenAIResourceGroup

                            # Ensure the AOAI_LOCATION environment variable is set
                            if (-not $env:AOAI_LOCATION) {
                                   $visionLocation = Read-Host "Please enter the location for your Azure OpenAI resources"
                                   azd env set AOAI_LOCATION $visionLocation
                            }
                     }
              }
              else {
                     azd env set OPENAI_DEMO "false"
              }
       }

       # Ensure the SEARCH_DEMO environment variable is set
       if (-not $env:SEARCH_DEMO) {
              $SearchDemo = Read-Host "Provision Search Demo? (y/n)"
              if ($SearchDemo -eq 'y') {
                     azd env set SEARCH_DEMO "true"
                     # Ensure the SEARCH_RESOURCE_GROUP environment variable is set
                     if (-not $env:SEARCH_RESOURCE_GROUP) {
                            $SearchResourceGroup = "search-${env:AZURE_ENV_NAME}-rg"
                            azd env set SEARCH_RESOURCE_GROUP $SearchResourceGroup
                     }
              }
              else {
                     azd env set SEARCH_DEMO "false"
              }
       }

       # Ensure the DOCINTEL_DEMO environment variable is set
       if (-not $env:DOCINTEL_DEMO) {
              $DocIntelDemo = Read-Host "Provision Document Intelligence Demo? (y/n)"
              if ($DocIntelDemo -eq 'y') {
                     azd env set DOCINTEL_DEMO "true"
                     # Ensure the DOCINTEL_RESOURCE_GROUP environment variable is set
                     if (-not $env:DOCINTEL_RESOURCE_GROUP) {
                            $DocIntelResourceGroup = "docintel-${env:AZURE_ENV_NAME}-rg"
                            azd env set DOCINTEL_RESOURCE_GROUP $DocIntelResourceGroup

                            # Ensure the DOCINTEL_LOCATION environment variable is set
                            if (-not $env:DOCINTEL_LOCATION) {
                                   $docIntelLocation = Read-Host "Please enter the location for your Document Intelligence resources"
                                   azd env set DOCINTEL_LOCATION $docIntelLocation
                            }
                     }
              }
              else {
                     azd env set DOCINTEL_DEMO "false"
              }
       }
}
Write-Host "Pre-provision script complete." -ForegroundColor Green