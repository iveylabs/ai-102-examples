
Write-Host "Running pre-provision script..."
$ProvisionAllDemos = Read-Host "Provision all demos? (y/n)"
if ($ProvisionAllDemos -eq 'y') {
       # Intro
       azd env set INTRO_DEMO "true"
       if (-not $env:INTRO_RESOURCE_GROUP) {
              # Ensure the INTRO_RESOURCE_GROUP environment variable is set
              $IntroResourceGroup = Read-Host "Please enter the desired name for your Intro resource group"
              azd env set INTRO_RESOURCE_GROUP $IntroResourceGroup
       }
       # Vision
       azd env set VISION_DEMO "true"
       if (-not $env:VISION_RESOURCE_GROUP) {
              # Ensure the VISION_RESOURCE_GROUP environment variable is set
              $VisionResourceGroup = Read-Host "Please enter the desired name for your Vision resource group"
              azd env set VISION_RESOURCE_GROUP $VisionResourceGroup
       }
       # Language
       azd env set LANGUAGE_DEMO "true"
       # Ensure the LANGUAGE_RESOURCE_GROUP environment variable is set
       if (-not $env:LANGUAGE_RESOURCE_GROUP) {
              $LanguageResourceGroup = Read-Host "Please enter the desired name for your Language resource group"
              azd env set LANGUAGE_RESOURCE_GROUP $LanguageResourceGroup
       }
       # OpenAI
       azd env set OPENAI_DEMO "true"
       if (-not $env:OPENAI_RESOURCE_GROUP) {
              # Ensure the OPENAI_RESOURCE_GROUP environment variable is set
              $OpenAIResourceGroup = Read-Host "Please enter the desired name for your Azure OpenAI resource group"
              azd env set OPENAI_RESOURCE_GROUP $OpenAIResourceGroup
       }
       # Search
       azd env set SEARCH_DEMO "true"
       # Ensure the SEARCH_RESOURCE_GROUP environment variable is set
       if (-not $env:SEARCH_RESOURCE_GROUP) {
              $SearchResourceGroup = Read-Host "Please enter the desired name for your Search resource group"
              azd env set SEARCH_RESOURCE_GROUP $SearchResourceGroup
       }
       # Doc Intel
       azd env set DOCINTEL_DEMO "true"
       # Ensure the DOCINTEL_RESOURCE_GROUP environment variable is set
       if (-not $env:DOCINTEL_RESOURCE_GROUP) {
              $DocIntelResourceGroup = Read-Host "Please enter the desired name for your Doc Intel resource group"
              azd env set DOCINTEL_RESOURCE_GROUP $DocIntelResourceGroup
       }
}
else {
       # Ensure the INTRO_DEMO environment variable is set
       if (-not $env:INTRO_DEMO) {
              $IntroDemo = Read-Host "Provision Intro Demo? (y/n)"
              if ($IntroDemo -eq 'y') {
                     azd env set INTRO_DEMO "true"
                     if (-not $env:INTRO_RESOURCE_GROUP) {
                            # Ensure the INTRO_RESOURCE_GROUP environment variable is set
                            $IntroResourceGroup = Read-Host "Please enter the desired name for your Intro resource group"
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
                            $VisionResourceGroup = Read-Host "Please enter the desired name for your Vision resource group"
                            azd env set VISION_RESOURCE_GROUP $VisionResourceGroup
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
                            $LanguageResourceGroup = Read-Host "Please enter the desired name for your Language resource group"
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
                            $OpenAIResourceGroup = Read-Host "Please enter the desired name for your Azure OpenAI resource group"
                            azd env set OPENAI_RESOURCE_GROUP $OpenAIResourceGroup
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
                            $SearchResourceGroup = Read-Host "Please enter the desired name for your Search resource group"
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
                            $DocIntelResourceGroup = Read-Host "Please enter the desired name for your Doc Intel resource group"
                            azd env set DOCINTEL_RESOURCE_GROUP $DocIntelResourceGroup
                     }
              }
              else {
                     azd env set DOCINTEL_DEMO "false"
              }
       }
}
Write-Host "Pre-provision script complete." -ForegroundColor Green