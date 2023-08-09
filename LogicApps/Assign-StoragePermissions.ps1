<#
.SYNOPSIS
Assigns GET Secret permissions to the specified StorageAccount for the managed identity of a LogicApp service.

.DESCRIPTION
Prior to running this script ensure you are authenticated against Azure and have the desired subscription set.

.PARAMETER subscriptionId
The Azure subscription ID where the StorageAccount and Logic App service are located.

.PARAMETER stoResourceGroupName
Name of the Resource Group that the StorageAccount instance is in.

.PARAMETER storageAccountName
Name of the StorageAccount for the AccessPolicy assignment scope.

.PARAMETER logicAppResourceGroupName
Name of the resource group where the Logic App is located.

.PARAMETER logicAppName
Name of the Logic App that will be used for the AccessPolicy assignment.

.EXAMPLE
./Assign-StorageAccountPermissions.ps1 -subscriptionId "<azure-subs-id>" -stoResourceGroupName "<sto-resource-group>" -storageAccountName "<storageaccount>" -logicAppResourceGroupName "<logic-app-resource-group>" -logicAppName "<logic-app>"
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory = $true)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $subscriptionId,
    [parameter(Mandatory = $true)]
    [string] $stoResourceGroupName,
    [parameter(Mandatory = $true)]
    [string] $storageAccountName,
    [parameter(Mandatory = $true)]
    [string] $logicAppResourceGroupName,
    [parameter(Mandatory = $true)]
    [string] $logicAppName
)

if ($subscriptionId -eq "") {
    Write-Host "No Azure subscription ID specified, finding from current active subscription"

    $subscriptionId = az account show | ConvertFrom-Json | Select-Object -ExpandProperty id

    if ($subscriptionId) {
        Write-Host "Found subscription ID $subscriptionId"
    }
    else {
        throw "No subscription ID found, an active subscription may not have been set in the Azure CLI"
    }
}

# --------------------------------------------------------------------------

Write-Host "Getting managed identity principal ID for Logic App $logicAppName"

$principalId = az logicapp show --name $logicAppName --resource-group $logicAppResourceGroupName | ConvertFrom-Json | Select-Object -ExpandProperty identity | Select-Object -ExpandProperty principalId

# Reset console colour because the show command breaks the colours and outputs black on black
[Console]::ResetColor()

if ($principalId) {
    Write-Host "Principal ID is $principalId"
}
else {
    throw "Unable to get managed identity principal ID for $logicAppName"
}

Write-Host "Adding AccessPolicy for $principalId to StorageAccount $storageAccountName"

az role assignment create --assignee-object-id $principalId --role 'Storage Blob Data Contributor' --scope /subscriptions/$subscriptionId/resourceGroups/$stoResourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName

Write-Host "Assigned AccessPolicy for Logic App $logicAppName to $storageAccountName for reading/writing blobs"
