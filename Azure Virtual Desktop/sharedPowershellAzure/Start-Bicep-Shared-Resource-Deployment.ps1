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
        -subscriptionId "abcdef-1234-1234-abcd-abcdef123456"`
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
    $deploymentName = "deploy-" + $($templateParameterFile.Split("\").Split(".")[1].Split("-")[0].toLower()) + "-shared-resources-" + $(Get-Date -Format "yyyy-MM-dd_HH-mm")
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
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set rg_shared_network_Id to: "$($result.outputs.rg_shared_network_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_network_Id;isoutput=true]$($result.outputs.rg_shared_network_Id.Value)"
    Write-Host "Set rg_shared_network_Name to: "$($result.outputs.rg_shared_network_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_network_Name;isoutput=true]$($result.outputs.rg_shared_network_Name.Value)"
    Write-Host "Set rg_shared_maintenance_Id to: "$($result.outputs.rg_shared_maintenance_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_maintenance_Id;isoutput=true]$($result.outputs.rg_shared_maintenance_Id.Value)"
    Write-Host "Set rg_shared_maintenance_Name to: "$($result.outputs.rg_shared_maintenance_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_maintenance_Name;isoutput=true]$($result.outputs.rg_shared_maintenance_Name.Value)"
    Write-Host "Set rg_shared_storage_Id to: "$($result.outputs.rg_shared_storage_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_storage_Id;isoutput=true]$($result.outputs.rg_shared_storage_Id.Value)"
    Write-Host "Set rg_shared_storage_Name to: "$($result.outputs.rg_shared_storage_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_storage_Name;isoutput=true]$($result.outputs.rg_shared_storage_Name.Value)"
    Write-Host "Set rg_shared_image_Id to: "$($result.outputs.rg_shared_image_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_image_Id;isoutput=true]$($result.outputs.rg_shared_image_Id.Value)"
    Write-Host "Set rg_shared_image_Name to: "$($result.outputs.rg_shared_image_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_image_Name;isoutput=true]$($result.outputs.rg_shared_image_Name.Value)"
    Write-Host "Set rg_shared_master_Id to: "$($result.outputs.rg_shared_master_Id.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_master_Id;isoutput=true]$($result.outputs.rg_shared_master_Id.Value)"
    Write-Host "Set rg_shared_master_Name to: "$($result.outputs.rg_shared_master_Name.Value)
    Write-Host "##vso[task.setvariable variable=rg_shared_master_Name;isoutput=true]$($result.outputs.rg_shared_master_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set shared_network_Id to: "$($result.outputs.shared_network_Id.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Id;isoutput=true]$($result.outputs.shared_network_Id.Value)"
    Write-Host "Set shared_network_Name to: "$($result.outputs.shared_network_Name.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Name;isoutput=true]$($result.outputs.shared_network_Name.Value)"
    Write-Host "Set shared_network_AddressPrefix to: "$($result.outputs.shared_network_AddressPrefix.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_AddressPrefix;isoutput=true]$($result.outputs.shared_network_AddressPrefix.Value)"
    Write-Host "Set shared_network_PrimaryDNS to: "$($result.outputs.shared_network_PrimaryDNS.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_PrimaryDNS;isoutput=true]$($result.outputs.shared_network_PrimaryDNS.Value)"
    Write-Host "Set shared_network_SecondaryDNS to: "$($result.outputs.shared_network_SecondaryDNS.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_SecondaryDNS;isoutput=true]$($result.outputs.shared_network_SecondaryDNS.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set shared_network_Peering_OpenSystems_Vnet_Id to: "$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Id.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_OpenSystems_Vnet_Id;isoutput=true]$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Id.Value)"
    Write-Host "Set shared_network_Peering_OpenSystems_Vnet_Name to: "$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Name.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_OpenSystems_Vnet_Name;isoutput=true]$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Name.Value)"
    Write-Host "Set shared_network_Peering_OpenSystems_Vnet_RG to: "$($result.outputs.shared_network_Peering_OpenSystems_Vnet_RG.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_OpenSystems_Vnet_RG;isoutput=true]$($result.outputs.shared_network_Peering_OpenSystems_Vnet_RG.Value)"
    Write-Host "Set shared_network_Peering_OpenSystems_Vnet_Subscription to: "$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Subscription.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_OpenSystems_Vnet_Subscription;isoutput=true]$($result.outputs.shared_network_Peering_OpenSystems_Vnet_Subscription.Value)"
    Write-Host "Set shared_network_Peering_Core_Vnet_Id to: "$($result.outputs.shared_network_Peering_Core_Vnet_Id.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_Core_Vnet_Id;isoutput=true]$($result.outputs.shared_network_Peering_Core_Vnet_Id.Value)"
    Write-Host "Set shared_network_Peering_Core_Vnet_Name to: "$($result.outputs.shared_network_Peering_Core_Vnet_Name.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_Core_Vnet_Name;isoutput=true]$($result.outputs.shared_network_Peering_Core_Vnet_Name.Value)"
    Write-Host "Set shared_network_Peering_Core_Vnet_RG to: "$($result.outputs.shared_network_Peering_Core_Vnet_RG.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_Core_Vnet_RG;isoutput=true]$($result.outputs.shared_network_Peering_Core_Vnet_RG.Value)"
    Write-Host "Set shared_network_Peering_Core_Vnet_Subscription to: "$($result.outputs.shared_network_Peering_Core_Vnet_Subscription.Value)
    Write-Host "##vso[task.setvariable variable=shared_network_Peering_Core_Vnet_Subscription;isoutput=true]$($result.outputs.shared_network_Peering_Core_Vnet_Subscription.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set routeTable_Shared_Id to: "$($result.outputs.routeTable_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=routeTable_Shared_Id;isoutput=true]$($result.outputs.routeTable_Shared_Id.Value)"
    Write-Host "Set routeTable_Shared_Name to: "$($result.outputs.routeTable_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=routeTable_Shared_Name;isoutput=true]$($result.outputs.routeTable_Shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set nsg_avd_endpoints_Shared_Id to: "$($result.outputs.nsg_avd_endpoints_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=nsg_avd_endpoints_Shared_Id;isoutput=true]$($result.outputs.nsg_avd_endpoints_Shared_Id.Value)"
    Write-Host "Set nsg_avd_endpoints_Shared_Name to: "$($result.outputs.nsg_avd_endpoints_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=nsg_avd_endpoints_Shared_Name;isoutput=true]$($result.outputs.nsg_avd_endpoints_Shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set snet_avd_cluster_endpoints_Shared_Id to: "$($result.outputs.snet_avd_cluster_endpoints_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_endpoints_Shared_Id;isoutput=true]$($result.outputs.snet_avd_cluster_endpoints_Shared_Id.Value)"
    Write-Host "Set snet_avd_cluster_endpoints_Shared_Name to: "$($result.outputs.snet_avd_cluster_endpoints_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_endpoints_Shared_Name;isoutput=true]$($result.outputs.snet_avd_cluster_endpoints_Shared_Name.Value)"
    Write-Host "Set snet_avd_cluster_endpoints_Shared_AddressPrefix to: "$($result.outputs.snet_avd_cluster_endpoints_Shared_AddressPrefix.Value)
    Write-Host "##vso[task.setvariable variable=snet_avd_cluster_endpoints_Shared_AddressPrefix;isoutput=true]$($result.outputs.snet_avd_cluster_endpoints_Shared_AddressPrefix.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set st_fslp_shared_region_Id to: "$($result.outputs.st_fslp_shared_region_Id.Value)
    Write-Host "##vso[task.setvariable variable=st_fslp_shared_region_Id;isoutput=true]$($result.outputs.st_fslp_shared_region_Id.Value)"
    Write-Host "Set st_fslp_shared_region_Name to: "$($result.outputs.st_fslp_shared_region_Name.Value)
    Write-Host "##vso[task.setvariable variable=st_fslp_shared_region_Name;isoutput=true]$($result.outputs.st_fslp_shared_region_Name.Value)"
    Write-Host "Set pep_st_fslp_shared_Id to: "$($result.outputs.pep_st_fslp_shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=pep_st_fslp_shared_Id;isoutput=true]$($result.outputs.pep_st_fslp_shared_Id.Value)"
    Write-Host "Set pep_st_fslp_shared_Name to: "$($result.outputs.pep_st_fslp_shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=pep_st_fslp_shared_Name;isoutput=true]$($result.outputs.pep_st_fslp_shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set automationAccount_Shared_Id to: "$($result.outputs.automationAccount_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=automationAccount_Shared_Id;isoutput=true]$($result.outputs.automationAccount_Shared_Id.Value)"
    Write-Host "Set automationAccount_Shared_Name to: "$($result.outputs.automationAccount_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=automationAccount_Shared_Name;isoutput=true]$($result.outputs.automationAccount_Shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set logAnalytics_Shared_Id to: "$($result.outputs.logAnalytics_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=logAnalytics_Shared_Id;isoutput=true]$($result.outputs.logAnalytics_Shared_Id.Value)"
    Write-Host "Set logAnalytics_Shared_Name to: "$($result.outputs.logAnalytics_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=logAnalytics_Shared_Name;isoutput=true]$($result.outputs.logAnalytics_Shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set recoveryVault_Shared_Id to: "$($result.outputs.recoveryVault_Shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=recoveryVault_Shared_Id;isoutput=true]$($result.outputs.recoveryVault_Shared_Id.Value)"
    Write-Host "Set recoveryVault_Shared_Name to: "$($result.outputs.recoveryVault_Shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=recoveryVault_Shared_Name;isoutput=true]$($result.outputs.recoveryVault_Shared_Name.Value)"
    Write-Host "----------------------------------------------------------------------------------------.Value)"
    Write-Host "Set computeGallery_shared_Id to: "$($result.outputs.computeGallery_shared_Id.Value)
    Write-Host "##vso[task.setvariable variable=computeGallery_shared_Id;isoutput=true]$($result.outputs.computeGallery_shared_Id.Value)"
    Write-Host "Set computeGallery_shared_Name to: "$($result.outputs.computeGallery_shared_Name.Value)
    Write-Host "##vso[task.setvariable variable=computeGallery_shared_Name;isoutput=true]$($result.outputs.computeGallery_shared_Name.Value)"

}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
