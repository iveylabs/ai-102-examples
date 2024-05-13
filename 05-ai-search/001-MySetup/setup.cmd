@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

rem Set values for your subscription and resource group
set subscription_id=SUBSCRIPTION_ID
set resource_group=RESOURCE_GROUP
set location=REGION
set storage_account_name=STORAGE_NAME
set multi_service_name=MULTI_SERVICE_NAME
set search_service_name=SEARCH_NAME

@REM echo Uploading files...
@REM rem Hack to get storage key
@REM for /f "tokens=*" %%a in ( 
@REM 'az storage account keys list --subscription !subscription_id! --resource-group !resource_group! --account-name !storage_account_name! --query "[?keyName=='key1'].{keyName:keyName, permissions:permissions, value:value}"' 
@REM ) do ( 
@REM set key_json=!key_json!%%a 
@REM ) 
@REM set key_string=!key_json:[ { "keyName": "key1", "permissions": "Full", "value": "=!
@REM set AZURE_STORAGE_KEY=!key_string:" } ]=!

@REM call az storage blob upload-batch -d margies-travel -s data --account-name !storage_account_name! --auth-mode key --account-key %AZURE_STORAGE_KEY%  --output none

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
