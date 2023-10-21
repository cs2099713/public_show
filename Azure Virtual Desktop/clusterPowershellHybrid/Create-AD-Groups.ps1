<#
.SYNOPSIS
    Creates AD Groups for fslogix profile permissions and avd access

.DESCRIPTION
    Must be run from a machine with ActiveDirectory module.
    Build for run via azure devops pipeline on hybrid worker.

.PARAMETER environmentType
    Mandatory. EnvironmentType e.g. prod

.PARAMETER LocationCode
    Mandatory. LocationCode e.g. weu

.PARAMETER SiteCode
    Mandatory. SiteCode e.g. de

.PARAMETER AppCode
    Mandatory. AppCode e.g. app01

.PARAMETER ouDnGroups
    Mandatory. Distinguished Name of organizational unit where groupd shall be created.

.INPUTS
    environmentType, LocationCode, SiteCode, AppCode, ouDnGroups

.EXAMPLE
    Create-AD-Groups `
        -environmentType "prod"`
        -LocationCode "weu"`
        -SiteCode "de"`
        -AppCode "app01"`
        -ouDnGroups "OU=Azure-AVD,OU=Azure AD Groups,OU=CONTONSO Groups,DC=CONTONSO,DC=COM"`

.NOTES
    Created by cs2099713 @03.2023
#>


Param
(
    [Parameter (Mandatory = $false)]
    [String] $environmentType,

    [Parameter (Mandatory = $false)]
    [String] $LocationCode,

    [Parameter (Mandatory = $true)]
    [String] $SiteCode,

    [Parameter (Mandatory = $true)]
    [String] $AppCode,

    [Parameter (Mandatory = $true)]
    [String] $ouDnGroups
)


try {
    Import-Module -Name ActiveDirectory
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Create AVD User Group
try {
    $avdUserGroup = "AVD-USERS-" + $environmentType.ToUpper() + "-" + $LocationCode.ToUpper() + "-" + $SiteCode.ToUpper() + "-" + $AppCode.ToUpper()
    Write-Host "Create Group: "$avdUserGroup
    Write-Host "in :"$ouDnGroups
    $avdAdminGroup = "AVD-ADMINS-" + $environmentType.ToUpper() + "-" + $LocationCode.ToUpper() + "-" + $SiteCode.ToUpper() + "-" + $AppCode.ToUpper()
    Write-Host "Create Group: "$avdAdminGroup
    Write-Host "in :"$ouDnGroups
    #revert to only new commands for security.
    try {
        Get-ADGroup $avdUserGroup
    }
    catch {
        New-ADGroup -Path $ouDnGroups -Name $avdUserGroup -GroupScope Universal -GroupCategory Security
    }
    try {
        Get-ADGroup $avdAdminGroup
    }
    catch {
        New-ADGroup -Path $ouDnGroups -Name $avdAdminGroup -GroupScope Universal -GroupCategory Security
    }
    Write-Host "avdUserGroup: "$avdUserGroup
    Write-Host "##vso[task.setvariable variable=avdUserGroup;isoutput=true]$($avdUserGroup)"
    Write-Host "avdAdminGroup: "$avdAdminGroup
    Write-Host "##vso[task.setvariable variable=avdAdminGroup;isoutput=true]$($avdAdminGroup)"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


