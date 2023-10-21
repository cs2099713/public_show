<#
.SYNOPSIS
    Starts bicep deployment of shared resources with given templatefile

.DESCRIPTION
    Starts bicep deployment of shared resources with given templatefile.
    Build for run via azure devops pipeline as azure powershell.

.PARAMETER subscriptionId
    Mandatory. Name or id of Azure subscription

.PARAMETER location
    Mandatory. Deployment location e.g. westeurope

.PARAMETER template
    Optional. Path to template file e.g. sharedDeployment/main-deploy-shared-resources.bicep

.PARAMETER templateParameterFile
    Mandatory. Path to template parameter file e.g. sharedParameters/WEU-shared-resources-parameters.json

.INPUTS
    subscriptionId, location, template, templateParameterFile

.EXAMPLE
    Bicep-Deployment `
        -subscriptionId "c527794d-f69c-43a5-b791-03ea78225e72"`
        -location "westeurope"`
        -template "sharedDeployment/main-deploy-shared-resources.bicep"`
        -templateParameterFile "sharedParameters/WEU-shared-resources-parameters.json"`

.NOTES
    Created by cs2099713 @03.2023
#>


Param
(
    [Parameter (Mandatory = $true)]
    [String] $subscriptionId,

    [Parameter (Mandatory = $true)]
    [String] $location,

    [Parameter (Mandatory = $true)]
    [String] $template,

    [Parameter (Mandatory = $true)]
    [String] $templateParameterFile
)
try {
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Actual AzContext:"
    Get-AzContext
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Param subscriptionId: "$subscriptionId
    Write-Host "Param location: "$location
    Write-Host "Param template: "$template
    Write-Host "Param templateParameterFile: "$templateParameterFile
    Write-Host "----------------------------------------------------------------------------------------"
    $deploymentName = "deploy-" + $templateParameterFile.split("/")[1].split("-")[2] + "-" + $templateParameterFile.split("/")[1].split("-")[3] + "-" + $templateParameterFile.split("/")[1].split("-")[0] + "-" + $templateParameterFile.split("/")[1].split("-")[1] + "-cluster-" + $(Get-Date -Format "yyyy-MM-dd_HH-mm")
    ##### START
    $result = New-AzDeployment -Name $deploymentName -Location $location -TemplateFile $template -TemplateParameterFile $templateParameterFile
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Output for deployment: "$($result.DeploymentName)
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Set tenantId to: "$($result.outputs.tenantId.Value)
    Write-Host "##vso[task.setvariable variable=tenantId;isoutput=true]$($result.outputs.tenantId.Value)"
    Write-Host "Set tenantName to: "$($result.outputs.tenantName.Value)
    Write-Host "##vso[task.setvariable variable=tenantName;isoutput=true]$($result.outputs.tenantName.Value)"
    Write-Host "Set subscription_ID to: "$($result.outputs.subscription_ID.Value)
    Write-Host "##vso[task.setvariable variable=subscription_ID;isoutput=true]$($result.outputs.subscription_ID.Value)"
    Write-Host "Set subscription_Name to: "$($result.outputs.subscription_Name.Value)
    Write-Host "##vso[task.setvariable variable=subscription_Name;isoutput=true]$($result.outputs.subscription_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Set rg_avd_cluster_core_Id to: "$($result.outputs.rg_avd_cluster_core_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_avd_cluster_core_Id;isoutput=true]$($result.outputs.rg_avd_cluster_core_Id.Value)"
    Write-Host "Set rg_avd_cluster_core_Name to: "$($result.outputs.rg_avd_cluster_core_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_avd_cluster_core_Name;isoutput=true]$($result.outputs.rg_avd_cluster_core_Name.Value)"
    Write-Host "Set rg_avd_cluster_hosts_Id to: "$($result.outputs.rg_avd_cluster_hosts_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_avd_cluster_hosts_Id;isoutput=true]$($result.outputs.rg_avd_cluster_hosts_Id.Value)"
    Write-Host "Set rg_avd_cluster_hosts_Name to: "$($result.outputs.rg_avd_cluster_hosts_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_avd_cluster_hosts_Name;isoutput=true]$($result.outputs.rg_avd_cluster_hosts_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Set nsg_avd_cluster_Id to: "$($result.outputs.nsg_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=nsg_avd_cluster_Id;isoutput=true]$($result.outputs.nsg_avd_cluster_Id.Value)"
    Write-Host "Set nsg_avd_cluster_Name to: "$($result.outputs.nsg_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=nsg_avd_cluster_Name;isoutput=true]$($result.outputs.nsg_avd_cluster_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Set snet_avd_cluster_hosts_Id to: "$($result.outputs.snet_avd_cluster_hosts_Id.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_hosts_Id;isoutput=true]$($result.outputs.snet_avd_cluster_hosts_Id.Value)"
    Write-Host "Set snet_avd_cluster_hosts_Name to: "$($result.outputs.snet_avd_cluster_hosts_Name.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_hosts_Name;isoutput=true]$($result.outputs.snet_avd_cluster_hosts_Name.Value)"
    Write-Host "Set snet_avd_cluster_hosts_AddressPrefix to: "$($result.outputs.snet_avd_cluster_hosts_AddressPrefix.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_hosts_AddressPrefix;isoutput=true]$($result.outputs.snet_avd_cluster_hosts_AddressPrefix.Value)"
    Write-Host "----------------------------------------------------------------------------------------"
    Write-Host "Set vdpool_avd_cluster_Id to: "$($result.outputs.vdpool_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=vdpool_avd_cluster_Id;isoutput=true]$($result.outputs.vdpool_avd_cluster_Id.Value)"
    Write-Host "Set vdpool_avd_cluster_Name to: "$($result.outputs.vdpool_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=vdpool_avd_cluster_Name;isoutput=true]$($result.outputs.vdpool_avd_cluster_Name.Value)"
    Write-Host "Set vdag_avd_cluster_Id to: "$($result.outputs.vdag_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=vdag_avd_cluster_Id;isoutput=true]$($result.outputs.vdag_avd_cluster_Id.Value)"
    Write-Host "Set vdag_avd_cluster_Name to: "$($result.outputs.vdag_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=vdag_avd_cluster_Name;isoutput=true]$($result.outputs.vdag_avd_cluster_Name.Value)"
    Write-Host "Set sp_avd_cluster_Id to: "$($result.outputs.sp_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=sp_avd_cluster_Id;isoutput=true]$($result.outputs.sp_avd_cluster_Id.Value)"
    Write-Host "Set sp_avd_cluster_Name to: "$($result.outputs.sp_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=sp_avd_cluster_Name;isoutput=true]$($result.outputs.sp_avd_cluster_Name.Value)"
    Write-Host "Set vdws_avd_cluster_Id to: "$($result.outputs.vdws_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=vdws_avd_cluster_Id;isoutput=true]$($result.outputs.vdws_avd_cluster_Id.Value)"
    Write-Host "Set vdws_avd_cluster_Name to: "$($result.outputs.vdws_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=vdws_avd_cluster_Name;isoutput=true]$($result.outputs.vdws_avd_cluster_Name.Value)"

    Write-Host "Set fslp_avd_cluster_Id to: "$($result.outputs.fslp_avd_cluster_Id.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_Id;isoutput=true]$($result.outputs.fslp_avd_cluster_Id.Value)"
    Write-Host "Set fslp_avd_cluster_Name to: "$($result.outputs.fslp_avd_cluster_Name.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_Name;isoutput=true]$($result.outputs.fslp_avd_cluster_Name.Value)"

    Write-Host "Set fslp_avd_cluster_parentStorageAccountID to: "$($result.outputs.fslp_avd_cluster_parentStorageAccountID.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_parentStorageAccountID;isoutput=true]$($result.outputs.fslp_avd_cluster_parentStorageAccountID.Value)"
    Write-Host "Set fslp_avd_cluster_parentStorageAccountName to: "$($result.outputs.fslp_avd_cluster_parentStorageAccountName.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_parentStorageAccountName;isoutput=true]$($result.outputs.fslp_avd_cluster_parentStorageAccountName.Value)"

    Write-Host "Set fslp_avd_cluster_resourceGroupID to: "$($result.outputs.fslp_avd_cluster_resourceGroupID.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_resourceGroupID;isoutput=true]$($result.outputs.fslp_avd_cluster_resourceGroupID.Value)"
    Write-Host "Set fslp_avd_cluster_resourceGroupName to: "$($result.outputs.fslp_avd_cluster_resourceGroupName.Value)
    Write-Host "##vso[task.setvariable variable=fslp_avd_cluster_resourceGroupName;isoutput=true]$($result.outputs.fslp_avd_cluster_resourceGroupName.Value)"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
