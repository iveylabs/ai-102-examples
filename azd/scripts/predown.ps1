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
# Get a list of all Azure OpenAI resources in the AOAI resource group (if applicable)
if($env:OPENAI_RESOURCE_GROUP) {
    Write-Host "Running pre-down script..."
    $aoaiResources = az cognitiveservices account list -g $env:OPENAI_RESOURCE_GROUP --query "[].name" -o tsv

    # Warn of the AOAI resources that will be deleted
    if($aoaiResources) {
        Write-Host "This azd down action $aoaiResources delete the following Azure OpenAI resources:"
        foreach ($resource in $aoaiResources) {
            Write-Host $resource
        }
        foreach ($resource in $aoaiResources) {
            $aoaiDeployments = az cognitiveservices account deployment list -g $env:OPENAI_RESOURCE_GROUP -n $resource --query "[].name" -o tsv
            if($aoaiDeployments) {
                Write-Host "$($resource) has the following deployments, which will be deleted:" -ForegroundColor Magenta
                foreach ($deployment in $aoaiDeployments) {
                    Write-Host "    $($deployment)" -ForegroundColor Magenta
                }
            }
        }
        # Cancel azd down
        if(-not (Get-Confirmation "Are you sure you want to continue this action? (Y/n)")) {
            Write-Host "Failing pre-down script with an exit code of 1 to cancel azd down" -ForegroundColor Cyan
            Exit 1
        }
        # Delete existing AOAI deployments in the relevant resource group
        else {
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
    Write-Host "Pre-down script complete." -ForegroundColor Green
}