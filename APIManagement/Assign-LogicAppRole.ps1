<#
.SYNOPSIS
Assigns a role to the specified resource group for the managed identity of the API Management service.

.DESCRIPTION
Prior to running this script ensure you are authenticated against Azure and have the desired subscription set.

.PARAMETER subscriptionId
The Azure subscription ID where the resource group is located.

.PARAMETER resourceGroupName
Name of the resource group for the role assignment scope.

.PARAMETER apimInstanceName
Name of the API Management service that will be used for the role assignment.

.PARAMETER apimResourceGroupName
Name of the resource group where the API Management service is located.

.PARAMETER role
The role to assign to the resource group for the API Management service managed identity.

.EXAMPLE
./Assign-LogicAppRole.ps1 -subscriptionId "<azure-subs-id>" -resourceGroupName "<resource-group>" -apimInstanceName "<apim-instance>" -apimResourceGroupName "<apim-resource-group>" -role "Get Logic App Callback Url xxxxx"
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory = $true)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $subscriptionId,
    [parameter(Mandatory = $true)]
    [string] $resourceGroupName,
    [parameter(Mandatory = $true)]
    [string] $apimInstanceName,
    [parameter(Mandatory = $true)]
    [string] $apimResourceGroupName,
    [parameter(Mandatory = $true)]
    [string] $role
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

Write-Host "Adding role assignment for $principalId to role $role for resource group $resourceGroupName"

az role assignment create --assignee $principalId --role "$role" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName

Write-Host "Assigned managed identity of API Management service $apimInstanceName to $resourceGroupName"
