@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

rem Set values for your subscription and resource group
set subscription_id=SUBSCRIPTION_ID
set resource_group=SEARCH_RESOURCE_GROUP
set location=REGION
set storage_account_name=STORAGE_ACCOUNT_NAME
set multi_service_name=MULTI_ACCOUNT_NAME
set search_service_name=SEARCH_KEY

echo Uploading files...
rem Hack to get storage key
for /f "tokens=*" %%a in ( 
'az storage account keys list --subscription !subscription_id! --resource-group !resource_group! --account-name !storage_account_name! --query "[?keyName=='key1'].{keyName:keyName, permissions:permissions, value:value}"' 
) do ( 
set key_json=!key_json!%%a 
) 
set key_string=!key_json:[ { "keyName": "key1", "permissions": "Full", "value": "=!
set AZURE_STORAGE_KEY=!key_string:" } ]=!

call az storage blob upload-batch -d margies-travel -s data --account-name !storage_account_name! --auth-mode key --account-key %AZURE_STORAGE_KEY%  --output none

rem Set values for your Search service
set url=https://!search_service_name!.search.windows.net
rem Get the Azure AI Search service admin key
for /f "tokens=*" %%a in ( 
'az search admin-key show --subscription !subscription_id! --resource-group !resource_group! --service-name !search_service_name! --query "primaryKey"' 
) do ( 
set admin_key=%%a 
)

echo -----
echo Creating the data source...
call curl -X POST %url%/datasources?api-version=2020-06-30 -H "Content-Type: application/json" -H "api-key: %admin_key%" -d @data_source.json

echo -----
echo Creating the skillset...
call curl -X PUT %url%/skillsets/margies-skillset?api-version=2020-06-30 -H "Content-Type: application/json" -H "api-key: %admin_key%" -d @skillset.json

echo -----
echo Creating the index...
call curl -X PUT %url%/indexes/margies-index?api-version=2020-06-30 -H "Content-Type: application/json" -H "api-key: %admin_key%" -d @index.json

rem wait
timeout /t 3 /nobreak

echo -----
echo Creating the indexer...
call curl -X PUT %url%/indexers/margies-indexer?api-version=2020-06-30 -H "Content-Type: application/json" -H "api-key: %admin_key%" -d @indexer.json
