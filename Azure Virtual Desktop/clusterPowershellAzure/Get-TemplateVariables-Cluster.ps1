<#
.SYNOPSIS
    Gets variables from template file of cluster resource deployments and creates devops pipeline output.

.DESCRIPTION
    Gets variables from template file of cluster resource deployments and creates devops pipeline output.
    Build for run via azure devops pipeline as azure powershell.

.PARAMETER templateParameterFile
    Mandatory. Path to template parameter file e.g. clusterParameters/dll-exacc-weu-prod-main-deploy-parameters.json

.INPUTS
    templateParameterFile

.EXAMPLE
    Get-TemplateVariables -templateParameterFile "clusterParameters/WEU-shared-resources-parameters.json"

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
    $DeploymentTenantId = (Get-AzContext).Tenant.Id
    $DeploymentSubscriptionName = (Get-AzContext).Subscription.Name
    $DeploymentSubscriptionId = (Get-AzContext).Subscription.id
    $dtnow = Get-Date -Format "yyyy-MM-dd HH:mm zzz"

    $obj = (Get-Content -Raw -Path $templateParameterFile | ConvertFrom-Json).Parameters
    #---------------------------------------------------------------------------------------------------------
    Write-Host "Set DeploymentTenantId to: "$DeploymentTenantId
    Write-Host "##vso[task.setvariable variable=DeploymentTenantId;isoutput=true]$DeploymentTenantId"

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

    Write-Host "Set siteCode to: "$($obj.siteCode.value)
    Write-Host "##vso[task.setvariable variable=siteCode;isoutput=true]$($obj.siteCode.value)"

    Write-Host "Set appCode to: "$($obj.appCode.value)
    Write-Host "##vso[task.setvariable variable=appCode;isoutput=true]$($obj.appCode.value)"
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
    Write-Host "Set snetHostsPrefix to: "$($obj.snetHostsPrefix.value)
    Write-Host "##vso[task.setvariable variable=snetHostsPrefix;isoutput=true]$($obj.snetHostsPrefix.value)"

    Write-Host "Set maxSessions to: "$($obj.maxSessions.value)
    Write-Host "##vso[task.setvariable variable=maxSessions;isoutput=true]$($obj.maxSessions.value)"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

