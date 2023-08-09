<#
.SYNOPSIS
Deploys a workflow project (as a Kudu ZIP Fiel dpeloyment) to a LogicApp service.

.DESCRIPTION
Prior to running this script ensure you are authenticated against Azure and have the desired subscription set.

.PARAMETER subscriptionId
The Azure subscription ID where the Logic App service is located.

.PARAMETER workflowFolder
Path (relative or absolute) to the workflow project structure.

.PARAMETER logicAppResourceGroupName
Name of the resource group where the Logic App is located.

.PARAMETER logicAppName
Name of the Logic App that will be used for the AccessPolicy assignment.

.EXAMPLE
./Deploy-LogicApp-Workflows.ps1 -subscriptionId "<azure-subs-id>" -workflowFolder "<workflow-folder>" -logicAppResourceGroupName "<logic-app-resource-group>" -logicAppName "<logic-app>"
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory = $true)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $subscriptionId,
    [parameter(Mandatory = $true)]
    [string] $workflowFolder,
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

Write-Host "Creating zip file for folder $workflowFolder"
$relativeFolderPath = Resolve-Path -Relative $workflowFolder
Write-Host "Relative path: $relativeFolderPath"

$workflowFolderName = Split-Path -Leaf $relativeFolderPath 
$workflowArchivePath = Split-Path -Path $relativeFolderPath
$zipFilePath = "$workflowArchivePath\$workflowFolderName.zip"
Write-Host "Creating zip file: $zipFilePath"
Compress-Archive -Path $workflowFolder\* -DestinationPath $zipFilePath -Force

Write-Host "Deploying ZIP file to Logic App $logicAppName"
az logicapp deployment source config-zip --resource-group $logicAppResourceGroupName --name $logicAppName --src $zipFilePath

Write-Host "Deployed workflows to Logic App $logicAppName"
