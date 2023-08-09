<#
.SYNOPSIS
Assigns Table Contributor permissions to the specified StorageAccount for the managed identity of an APIM service.

.DESCRIPTION
Prior to running this script ensure you are authenticated against Azure and have the desired subscription set.

.PARAMETER subscriptionId
The Azure subscription ID where the StorageAccount and APIM service are located.

.PARAMETER stoResourceGroupName
Name of the Resource Group that the StorageAccount instance is in.

.PARAMETER storageAccountName
Name of the StorageAccount for the AccessPolicy assignment scope.

.PARAMETER apimResourceGroupName
Name of the resource group where the APIM instance is located.

.PARAMETER apimInstanceName
Name of the APIM Instance that will be used for the AccessPolicy assignment.

.EXAMPLE
./Assign-ApimStorageAccountPermissions.ps1 -subscriptionId "<azure-subs-id>" -stoResourceGroupName "<sto-resource-group>" -storageAccountName "<storageaccount>" -apimResourceGroupName "<apim-resource-group>" -apimInstanceName "<apim-instance>"
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
    [string] $apimResourceGroupName,
    [parameter(Mandatory = $true)]
    [string] $apimInstanceName
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

$role = "Storage Table Data Contributor"

Write-Host "Getting managed identity principal ID for API Management service $apimInstanceName"

$principalId = az apim show --name $apimInstanceName --resource-group $apimResourceGroupName | ConvertFrom-Json | Select-Object -ExpandProperty identity | Select-Object -ExpandProperty principalId

# Reset console colour because the show command breaks the colours and outputs black on black
[Console]::ResetColor()

if ($principalId) {
    Write-Host "Principal ID is $principalId"
}
else {
    throw "Unable to get managed identity principal ID for $apimInstanceName"
}

Write-Host "Adding role assignment for $principalId to role '$role' for storage account $storageAccountName"

az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role $role --scope /subscriptions/$subscriptionId/resourceGroups/$stoResourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName

Write-Host "Assigned managed identity of API Management service $apimInstanceName to $storageAccountName"

