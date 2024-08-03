Write-Host "Running pre-down script..." -ForegroundColor Cyan

# Get a list of all Azure OpenAI resources in the AOAI resource group (if applicable)
if($env:OPENAI_RESOURCE_GROUP -and $env:OPENAI_DEMO -eq "true") {
    $aoaiResources = az cognitiveservices account list -g $env:OPENAI_RESOURCE_GROUP --query "[].name" -o tsv

    # List the AOAI resources that will be deleted
    if($aoaiResources) {
        foreach ($resource in $aoaiResources) {
            $aoaiDeployments = az cognitiveservices account deployment list -g $env:OPENAI_RESOURCE_GROUP -n $resource --query "[].name" -o tsv
            if($aoaiDeployments) {
                Write-Host "$($resource) has the following deployments, which will be deleted:" -ForegroundColor Magenta
                foreach ($deployment in $aoaiDeployments) {
                    Write-Host "    $($deployment)" -ForegroundColor Magenta
                }
            }
        }
        # Delete existing AOAI deployments in the relevant resource group
        foreach ($resource in $aoaiResources) {
            $aoaiDeployments = az cognitiveservices account deployment list -g $env:OPENAI_RESOURCE_GROUP -n $resource --query "[].name" -o tsv
            if($aoaiDeployments) {
                Write-Host "Deleting deployments for $($resource)..." -ForegroundColor Cyan
                $number = 0
                foreach ($deployment in $aoaiDeployments) {
                    try {
                        $output = az cognitiveservices account deployment delete -g $env:OPENAI_RESOURCE_GROUP -n $resource --deployment-name $deployment 2>&1
                        if (-not $?) {
                            throw $output
                        }
                        $number++
                    }
                    catch {
                        Write-Host "Failed to delete deployment $($deployment) from resource $($resource). $output `nPlease delete the deployments manually and try azd down again" -ForegroundColor Red
                        Exit 1
                    }
                }
                Write-Host "Successfully deleted $($number) deployment(s) from the resource $($resource)" -ForegroundColor Green
            }
        }
    }
}

# Permanently delete all Azure Machine Learning Workspace resources in the Vision resource group (if applicable)
if($env:VISION_RESOURCE_GROUP -and $env:VISION_DEMO -eq "true") {
    # Install the ml Azure CLI extension
    Write-Host "Ensuring the latest AML extension for the Azure CLI is installed..." -ForegroundColor Cyan
    try {
        az extension add -n ml
        az extension update -n ml
        Write-Host "The latest AML Azure CLI extension is installed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed install/update the AML Azure CLI extension." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.Exception.ItemName -ForegroundColor Red
    }
    $amlResources = az ml workspace list -g $env:VISION_RESOURCE_GROUP --query "[].name" -o tsv
    if($amlResources) {
        foreach($resource in $amlResources) {
            Write-Host "Permanently deleting AML Workspace $($resource) and all related resources..." -ForegroundColor Cyan
            try {
                $output = az ml workspace delete -g $env:VISION_RESOURCE_GROUP -n $resource --all-resources --no-wait -p -y 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Successfully deleted the AML Workspace $($resource)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to AML Workspace $($resource). $output `nPlease delete the AML Workspace manually and try azd down again" -ForegroundColor Red
                Exit 1
            }
        }
    }
}

Write-Host "Pre-down script complete." -ForegroundColor Green