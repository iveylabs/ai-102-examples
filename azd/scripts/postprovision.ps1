<#
.SYNOPSIS
Prompts the user for confirmation before an action is performed, returning $true or $false as applicable.

.DESCRIPTION
The `Get-Confirmation` function prompts the user to respond to a y/n prompt. The user can press ENTER to use the default value of Y. The function validates the response and loops until a valid response of y, n, or ENTER is received.

.PARAMETER message
The message to be displayed when prompting for a response. As the only parameter, you can either just put the message or specify the -message parameter followed by the message.

.EXAMPLE
Get-Confirmation "Would you like to do the thing? (Y/n)"

This example prompts the user and returns $true or $false depending on the response from the user.

.NOTES
- The function will prompt the user respond with either a y, n, or pressing ENTER.
- The function will loop until a response is received.
- The function returns $true or $false depending on the response received. If ENTER or y is received, $true is returned. Otherwise, $false is returned.
#>
function Get-Confirmation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    while ($true) {
        $confirmation = Read-Host $message
        # $true
        if ([string]::IsNullOrWhiteSpace($confirmation) -or $confirmation -eq 'y' ) {
            return $true
        }
        # $false
        elseif ($confirmation -eq 'n') {
            return $false
        }
        # Invalid entry
        else {
            Write-Host "Invalid selection. Please enter y or n." -ForegroundColor Yellow
        }
    }
}

Write-Host "Running post-provision script..." -ForegroundColor Cyan

if ($env:INTRO_DEMO -eq "true") {
    # Create the SP and assign permissions for demonstrating Key Vault access
    if (Get-Confirmation "Create the SP and assign permissions for demonstrating Key Vault access? (Y/n)") {
        try {
            Write-Host "Creating service principal..." -ForegroundColor Cyan
            $spOutput = (az ad sp create-for-rbac -n "introvaultsp" --role "Key Vault Secrets User" --scopes "/subscriptions/${env:AZURE_SUBSCRIPTION_ID}/resourceGroups/${env:INTRO_RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${env:vaultName}" -o json) | ConvertFrom-Json
            Write-Host "Service principal created successfully." -ForegroundColor Green
            # Save the service principal credentials to the .env file
            if (Get-Confirmation "Would you like to save the service principal credentials to the .env file? (Y/n)") {
                try {
                    Write-Host "Service principal credentials saved to the .env file." -ForegroundColor Green
                    azd env set SP_APP_ID $spOutput.appId
                    azd env set SP_PASSWORD $spOutput.password
                    azd env set SP_TENANT_ID $spOutput.tenant
                }
                catch {
                    Write-Host "Failed to save service principal credentials to the .env file." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Red
                    Write-Host $_.Exception.ItemName -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Failed to create and/or assign RBAC permissions for the service principal." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Service principal will not be created or configured.`n" -ForegroundColor Yellow
    }

}

if ($env:VISION_DEMO -eq "true") {
    # Upload image classification images to Blob Storage
    if (Get-Confirmation "Upload image classification images from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:VISION_RESOURCE_GROUP variable is set
            if (-not $env:VISION_RESOURCE_GROUP) {
                Write-Host "VISION_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:VISION_RESOURCE_GROUP --query "[0].name" --output tsv
            # If accountName is empty, the storage account hasn't been created yet
            $sourcePath = "../02-vision/02-image-classification/training-images"

            Write-Host "Uploading image classification images to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "classification" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Image classification images uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload image classification images. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload image classification images." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Image classification images won't be uploaded.`n" -ForegroundColor Yellow
    }

    # Upload object detection images to Blob Storage
    if (Get-Confirmation "Upload object detection images from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:VISION_RESOURCE_GROUP variable is set
            if (-not $env:VISION_RESOURCE_GROUP) {
                Write-Host "VISION_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:VISION_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../02-vision/03-object-detection/training-images"

            Write-Host "Uploading object detection images to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "detection" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Object detection images uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload object detection images. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload custom object detection images." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Object detection images won't be uploaded.`n" -ForegroundColor Yellow
    }
}

if ($env:LANGUAGE_DEMO -eq "true") {
    # Upload custom text classification files to Blob Storage
    if (Get-Confirmation "Upload custom text classification files from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:LANGUAGE_RESOURCE_GROUP variable is set
            if (-not $env:LANGUAGE_RESOURCE_GROUP) {
                Write-Host "LANGUAGE_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:LANGUAGE_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../03-nlp/03-custom-classification/articles_train"

            Write-Host "Uploading custom text classification files to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "classification" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Custom text classification files uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload custom text classification files. $output" -ForegroundColor Red
            }
            
        }
        catch {
            Write-Host "Failed to upload custom text classification files." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Custom text classification files won't be uploaded.`n" -ForegroundColor Yellow
    }

    # Upload custom NER files to Blob Storage
    if (Get-Confirmation "Upload custom NER files from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:LANGUAGE_RESOURCE_GROUP variable is set
            if (-not $env:LANGUAGE_RESOURCE_GROUP) {
                Write-Host "LANGUAGE_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:LANGUAGE_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../03-nlp/04-custom-ner/ads_train"

            Write-Host "Uploading custom NER files to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "entityrecognition" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Custom NER files uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload custom NER files. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload custom NER files." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Custom NER files won't be uploaded.`n" -ForegroundColor Yellow
    }
}

if ($env:SEARCH_DEMO -eq "true") {
    # Upload Search files to Blob Storage
    if (Get-Confirmation "Upload Search files from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:SEARCH_RESOURCE_GROUP variable is set
            if (-not $env:SEARCH_RESOURCE_GROUP) {
                Write-Host "SEARCH_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:SEARCH_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../05-ai-search/001-MySetup/data"

            Write-Host "Uploading Search files to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "margies-travel" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Search files uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload Search files. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload Search files." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Search files won't be uploaded.`n" -ForegroundColor Yellow
    }
}

if ($env:DOCINTEL_DEMO -eq "true") {
    # Upload Doc Intel custom training files to Blob Storage
    if (Get-Confirmation "Upload Doc Intel custom training files from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:DOCINTEL_RESOURCE_GROUP variable is set
            if (-not $env:DOCINTEL_RESOURCE_GROUP) {
                Write-Host "DOCINTEL_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:DOCINTEL_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../06-doc-intel/REST_Training"

            Write-Host "Uploading Doc Intel custom training files to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "customtraining" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "Doc Intel custom training files uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload Doc Intel custom training files. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload Doc Intel custom training files." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "Doc Intel custom training files won't be uploaded.`n" -ForegroundColor Yellow
    }
}

if ($env:OPENAI_DEMO -eq "true") {
    # Upload AOAI RAG files to Blob Storage
    if (Get-Confirmation "Upload RAG files from the repo? (Y/n)") {
        try {
            # Only proceed if the $env:OPENAI_RESOURCE_GROUP variable is set
            if (-not $env:OPENAI_RESOURCE_GROUP) {
                Write-Host "OPENAI_RESOURCE_GROUP environment variable is not set. Skipping image upload." -ForegroundColor Red
                return
            }
            $accountName = az storage account list --resource-group $env:OPENAI_RESOURCE_GROUP --query "[0].name" --output tsv
            $sourcePath = "../04-aoai/02-own-data"

            Write-Host "Uploading RAG files to Blob Storage..." -ForegroundColor Cyan

            try {
                $output = az storage blob upload-batch -d "rag" -s $sourcePath --account-name $accountName --auth-mode login 2>&1
                if (-not $?) {
                    throw $output
                }
                Write-Host "RAG files uploaded successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to upload RAG files. $output" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to upload RAG files." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.Exception.ItemName -ForegroundColor Red
        }
    }
    else {
        Write-Host "RAG files won't be uploaded.`n" -ForegroundColor Yellow
    }
}
Write-Host "Post-provision script complete." -ForegroundColor Green