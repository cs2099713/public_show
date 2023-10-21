<#
.SYNOPSIS
    Joins existing storage account to onprem AD as computer account.

.DESCRIPTION
    Must be run from a machine with Az, ActiveDirectory and AzHybridFiles module.
    Build for run via azure devops pipeline on hybrid worker.

.PARAMETER subscriptionId
    Mandatory. Name or id of Azure subscription

.PARAMETER resourceGroupName
    Mandatory. Name of resourcegroup where storage account is located

.PARAMETER storageAccountName
    Optional. Name storage account if not provided it will get name of storage account from resource group

.PARAMETER domain
    Mandatory. Name of on-premises domain

.PARAMETER ouDN
    Mandatory. Distinguished Name of organizational unit where storage account shall be joined.

.PARAMETER tenantId
    Mandatory. TenantId of Azure tenant

.PARAMETER appId
    Optional. AppId of app registration, with contributor or storage owner permissions on storage account

.PARAMETER thumbprint
    Optional. Certificate thumbprint of certificate in local personal user store, which allows to authenticate
    via SPN app registration.

.INPUTS
    thumbprint, appId, tenantId, subscriptionId, resourceGroupName, storageAccountName, domain, ouDN

.EXAMPLE
    Join-StorageAccount-AD `
        -thumbprint "abcdefghijklmnopqrstuvwxyz12345678901234"`
        -appId "abcdef-1234-1234-abcd-abcdef123456"`
        -tenantId "abcdef-1234-1234-abcd-abcdef123456"`
        -subscriptionId "sub-devops-sandbox"`
        -resourceGroupName "rg-avd-shared-storage-weu-prod"`
        -storageAccountName "test456789"`
        -domain "contonso.com"
        -ouDN "OU=Storageaccounts,OU=Azure VDI,DC=CONTONSO,DC=COM"

.NOTES
    Created by cs2099713 @03.2023
#>


Param
(
    [Parameter (Mandatory = $false)]
    [String] $thumbprint,

    [Parameter (Mandatory = $false)]
    [String] $appId,

    [Parameter (Mandatory = $true)]
    [String] $tenantId,

    [Parameter (Mandatory = $true)]
    [String] $subscriptionId,

    [Parameter (Mandatory = $true)]
    [String] $resourceGroupName,

    [Parameter (Mandatory = $false)]
    [String] $storageAccountName,

    [Parameter (Mandatory = $true)]
    [String] $domain,

    [Parameter (Mandatory = $true)]
    [String] $ouDN
)

Write-Host "appId: "$appId
Write-Host "tenantId: "$tenantId
Write-Host "subscriptionId: "$subscriptionId
Write-Host "resourceGroupName: "$resourceGroupName
Write-Host "storageAccountName: "$storageAccountName
Write-Host "domain: "$domain
Write-Host "ouDN: "$ouDN

try {
    Import-Module -Name AzFilesHybrid
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

if ($appId -eq $null -or $thumbprint -eq $null) {
    try {
        Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }

}
else {
    try {
        Connect-AzAccount -CertificateThumbprint $thumbprint -ApplicationId $appId -Tenant $tenantId -Subscription $subscriptionId
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Write-Host "Wait 5 seconds..."
Start-Sleep -s 5

try {
    if ($storageAccountName -eq $null -or $storageAccountName -eq "") {
    (Get-AzStorageAccount -ResourceGroupName $resourceGroupName).StorageAccountName
    }

    Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType "ComputerAccount" `
        -EncryptionType "'RC4','AES256'"`
        -Domain $domain `
        -OrganizationalUnitDistinguishedName $ouDN `
        -Confirm:$false
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


Write-Host "Wait 5 seconds..."
Start-Sleep -s 5

Write-Host $((Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).AzureFilesIdentityBasedAuth.DirectoryServiceOptions)
Write-Host $((Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).AzureFilesIdentityBasedAuth.ActiveDirectoryProperties)
