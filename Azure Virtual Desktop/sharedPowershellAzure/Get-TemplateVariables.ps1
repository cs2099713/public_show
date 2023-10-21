<#
.SYNOPSIS
    Gets variables from template file of shared resource deployments and creates devops pipeline output.

.DESCRIPTION
    Gets variables from template file of shared resource deployments and creates devops pipeline output.
    Build for run via azure devops pipeline as azure powershell.

.PARAMETER templateParameterFile
    Mandatory. Path to template parameter file e.g. sharedParameters/WEU-shared-resources-parameters.json

.INPUTS
    templateParameterFile

.EXAMPLE
    Get-TemplateVariables -templateParameterFile "sharedParameters/WEU-shared-resources-parameters.json"

.NOTES
    Created by cs2099713 @03.2023
#>


Param
(
    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $templateParameterFile
)

try {
    $DeploymentSubscriptionName = (Get-AzContext).Subscription.Name
    $DeploymentSubscriptionId = (Get-AzContext).Subscription.id
    $dtnow = Get-Date -Format "yyyy-MM-dd HH:mm zzz"

    $obj = (Get-Content -Raw -Path $templateParameterFile | ConvertFrom-Json).Parameters
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set DeploymentSubscriptionName to: "$DeploymentSubscriptionName
    Write-Host "##vso[task.setvariable variable=DeploymentSubscriptionName;isoutput=true]$DeploymentSubscriptionName"

    Write-Host "Set DeploymentSubscriptionId to: "$DeploymentSubscriptionId
    Write-Host "##vso[task.setvariable variable=DeploymentSubscriptionId;isoutput=true]$DeploymentSubscriptionId"

    Write-Host "Set dtnow to: "$dtnow
    Write-Host "##vso[task.setvariable variable=dtnow;isoutput=true]$dtnow"
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set location to: "$($obj.location.value)
    Write-Host "##vso[task.setvariable variable=location;isoutput=true]$($obj.location.value)"

    Write-Host "Set locationCode to: "$($obj.locationCode.value)
    Write-Host "##vso[task.setvariable variable=locationCode;isoutput=true]$($obj.locationCode.value)"

    Write-Host "Set environmentType to: "$($obj.environmentType.value)
    Write-Host "##vso[task.setvariable variable=environmentType;isoutput=true]$($obj.environmentType.value)"
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set tagsBilling to: "$($obj.tagsBilling.value)
    Write-Host "##vso[task.setvariable variable=tagsBilling;isoutput=true]$($obj.tagsBilling.value)"

    Write-Host "Set tagsBillingSite to: "$($obj.tagsBillingSite.value)
    Write-Host "##vso[task.setvariable variable=tagsBillingSite;isoutput=true]$($obj.tagsBillingSite.value)"

    Write-Host "Set tagsBillingService to: "$($obj.tagsBillingService.value)
    Write-Host "##vso[task.setvariable variable=tagsBillingService;isoutput=true]$($obj.tagsBillingService.value)"

    Write-Host "Set deploymentDate to: "$($obj.deploymentDate.value)
    Write-Host "##vso[task.setvariable variable=deploymentDate;isoutput=true]$($obj.deploymentDate.value)"

    Write-Host "Set deploymentSite to: "$($obj.deploymentSite.value)
    Write-Host "##vso[task.setvariable variable=deploymentSite;isoutput=true]$($obj.deploymentSite.value)"

    Write-Host "Set deploymentApp to: "$($obj.deploymentApp.value)
    Write-Host "##vso[task.setvariable variable=deploymentApp;isoutput=true]$($obj.deploymentApp.value)"

    Write-Host "Set deploymentRegion to: "$($obj.deploymentRegion.value)
    Write-Host "##vso[task.setvariable variable=deploymentRegion;isoutput=true]$($obj.deploymentRegion.value)"

    Write-Host "Set deploymentBy to: "$($obj.deploymentBy.value)
    Write-Host "##vso[task.setvariable variable=deploymentBy;isoutput=true]$($obj.deploymentBy.value)"
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set vnetAddressPrefix to: "$($obj.vnetAddressPrefix.value)
    Write-Host "##vso[task.setvariable variable=vnetAddressPrefix;isoutput=true]$($obj.vnetAddressPrefix.value)"

    Write-Host "Set primaryDNS to: "$($obj.primaryDNS.value)
    Write-Host "##vso[task.setvariable variable=primaryDNS;isoutput=true]$($obj.primaryDNS.value)"

    Write-Host "Set secondaryDNS to: "$($obj.secondaryDNS.value)
    Write-Host "##vso[task.setvariable variable=secondaryDNS;isoutput=true]$($obj.secondaryDNS.value)"

    Write-Host "Set snetEndpointsPrefix to: "$($obj.snetEndpointsPrefix.value)
    Write-Host "##vso[task.setvariable variable=snetEndpointsPrefix;isoutput=true]$($obj.snetEndpointsPrefix.value)"

    Write-Host "Set routeTableNextHopIPAddress to: "$($obj.routeTableNextHopIPAddress.value)
    Write-Host "##vso[task.setvariable variable=routeTableNextHopIPAddress;isoutput=true]$($obj.routeTableNextHopIPAddress.value)"
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set vnetName_OS to: "$($obj.vnetName_OS.value)
    Write-Host "##vso[task.setvariable variable=vnetName_OS;isoutput=true]$($obj.vnetName_OS.value)"

    Write-Host "Set vnetRG_OS to: "$($obj.vnetRG_OS.value)
    Write-Host "##vso[task.setvariable variable=vnetRG_OS;isoutput=true]$($obj.vnetRG_OS.value)"

    Write-Host "Set vnetSub_OS to: "$($obj.vnetSub_OS.value)
    Write-Host "##vso[task.setvariable variable=vnetSub_OS;isoutput=true]$($obj.vnetSub_OS.value)"

    Write-Host "Set vnetSubID_OS to: "$($obj.vnetSubID_OS.value)
    Write-Host "##vso[task.setvariable variable=vnetSubID_OS;isoutput=true]$($obj.vnetSubID_OS.value)"
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set vnetName_CORE to: "$($obj.vnetName_CORE.value)
    Write-Host "##vso[task.setvariable variable=vnetName_CORE;isoutput=true]$($obj.vnetName_CORE.value)"

    Write-Host "Set vnetRG_CORE to: "$($obj.vnetRG_CORE.value)
    Write-Host "##vso[task.setvariable variable=vnetRG_CORE;isoutput=true]$($obj.vnetRG_CORE.value)"

    Write-Host "Set vnetSub_CORE to: "$($obj.vnetSub_CORE.value)
    Write-Host "##vso[task.setvariable variable=vnetSub_CORE;isoutput=true]$($obj.vnetSub_CORE.value)"

    Write-Host "Set vnetSubID_CORE to: "$($obj.vnetSubID_CORE.value)
    Write-Host "##vso[task.setvariable variable=vnetSubID_CORE;isoutput=true]$($obj.vnetSubID_CORE.value)"

}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

