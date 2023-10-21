Param
(
    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $SyncedADGroupName,

    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $StorageRG,

    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $storageAccountName,

    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $subscriptionId,

    [Parameter (Mandatory = $true)]
    [String] $appId,

    [Parameter (Mandatory = $true)]
    [String] $thumbprint
)

Write-Host "appId: "$appId
Write-Host "subscriptionId: "$subscriptionId
Write-Host "SyncedADGroupName: "$SyncedADGroupName
Write-Host "StorageRG: "$StorageRG
Write-Host "StorageAccountName: "$StorageAccountName

try {
    $tenantId = $((Get-AzContext).Tenant.Id)
    Write-Host "tenantId: "$tenantId
    Connect-AzAccount -CertificateThumbprint $thumbprint -ApplicationId $appId -Tenant $tenantId -Subscription $subscriptionId
    Connect-MgGraph -ClientId $appId -TenantId $tenantId -CertificateThumbprint $thumbprint
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


Write-Output "Wait 5 seconds..."
Start-Sleep -s 5

try {
    $i = 0;
    while ($i -le 5) {
        $i++;
        $ADGroup = (Get-MGGroup -Filter "DisplayName eq '$SyncedADGroupName'")
        if (($null -ne $ADGroup)) {
            Write-Host $ADGroup.DisplayName
            Write-Host "Group synced! "$i
            $i = 6
        }
        else {
            Write-Host $SyncedADGroupName" not found. Waiting 10 minutes for Azure AD Sync... "$i
            Start-Sleep -Seconds 600
        }
    }
    if (($null -eq $ADGroup)) {
        Write-Error -Message $("Group: " + $SyncedADGroupName + " not found!")
    }
    Write-Host ($ADGroup.Id + "-" + $ADGroup.DisplayName)
    Write-Host "--------------------------------------------"
    Write-Host "Get-RoleDefinition"
    $ADRoleDefinition = Get-AzRoleDefinition "Storage File Data SMB Share Contributor"
    if (($null -eq $ADRoleDefinition)) {
        Write-Error -Message $("Roledefiniton not found!")
    }
    Write-Host ($ADRoleDefinition.Id + " - " + $ADRoleDefinition.Name)
    Write-Host "--------------------------------------------"
    Write-Host "Get-StorageAccount"
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageRG -Name $StorageAccountName
    if (($null -eq $StorageAccount)) {
        Write-Error -Message $("StorageAccount not found!")
    }
    Write-Host ($StorageAccount.Id + "-" + $StorageAccount.StorageAccountName)
    Write-Host "--------------------------------------------"
    Write-Host "New-Role-Assignment"
    New-AzRoleAssignment -ObjectId $ADGroup.Id -ResourceGroupName $StorageRG -ResourceName $StorageAccount.StorageAccountName -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName $ADRoleDefinition.Name
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
Write-Host $("Role for group " + $SyncedADGroupName + " successfully assigned to " + $StorageAccountName + " in " + $StorageRG)

