
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
    [String] $fileShareName,

    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $subscriptionId,

    [Parameter (Mandatory = $false)]
    [String] $appId,

    [Parameter (Mandatory = $false)]
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
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Write-Output "Wait 5 seconds..."
Start-Sleep -s 5

try {

    $avdUserGroup = $SyncedADGroupName
    $resourceGroupName = $StorageRG
    $StorageAccountURL = "$($storageAccountName).privatelink.file.core.windows.net"
    $root = "\\$($storageAccountName).privatelink.file.core.windows.net\$($fileshareName)"
    Write-Host $root
    #test connection from executing machine to storage account. Attention, often ISPs block SMB via Port 445.
    #best to run from azure vm.
    Write-Host "Connect..."
    $connectTestResult = Test-NetConnection -ComputerName $StorageAccountURL -Port 445
    if ($connectTestResult.TcpTestSucceeded) {
        Write-Host "Get stAccount"
        $username = "localhost\$($StorageAccountName)"
        $account = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
        Write-Host "Prepare mounting"
        $Cred = New-Object System.Management.Automation.PSCredential (
            $username,
            $(ConvertTo-SecureString $account -AsPlainText -Force)
        )
        Write-Host "Mount Share"
        New-PSDrive -Name avdStore -PSProvider FileSystem -Root $root -Credential $Cred

        #Set NTFS Permissions on share.
        <#
        Background Information:
        ------------------------------
        - FileSystemAccessRule Class Documentation: https://learn.microsoft.com/de-de/dotnet/api/system.security.accesscontrol.filesystemaccessrule?view=xamarinmac-3.0
            Constructors:
                FileSystemAccessRule(IdentityReference, FileSystemRights, AccessControlType)
                FileSystemAccessRule(IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags, AccessControlType)

        - Inheritance & Propagation combinations and their meaning:

                                                Propagation    |   Inheritance
            ---------------------------------------------------|-----------------
            + folder only:                          none       |       none
            + folder, sub-folders and files:        none       | Container|Object
            + folder and sub-folders:               none       |     Container
            + folder and files:                     none       |      Object
            + sub-folders and files:            InheritOnly    | Container|Object
            + sub-folders only:                 InheritOnly    |     Container
            + files only:                       InheritOnly    |      Object

        Requirement Specification:
        ------------------------------
        - Since Set-ACL can only work if the service account running has permissions to set permissions on everything
            ($accessSvcUser, FullControl, Container|Object, none, Allow)
        - Ever AVD user shall have modify access to share root, but not to subfolders or files
            ($accessUserGroup, Modify, Allow)
            This way a new user logging in will have permissions to create an fslogix profile folder for his user.
            The user creating this profile folder will be it's Owner.
        - Ever CREATOR OWNER shall have permissions on the root folder, all subfolders and files.
            (CREATOR OWNER, Modify, Container|Object, none, Allow)

    #>
        #Get actual acl
        Write-Host "Get acl"
        $acl = Get-Acl avdStore:

        #add adsvcdevops with full access and add acl rule to avdStore root including inheritance.
        $accessSvcAccount = New-Object System.Security.AccessControl.FileSystemAccessRule("lewa\adsvcdevops", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        Write-Host "Add permissions svc account"
        $acl.SetAccessRule($accessSvcAccount)

        #add avd user group with modify rights for root directory and add rule to avdStore root.
        $accessUserGroup = New-Object System.Security.AccessControl.FileSystemAccessRule($avdUserGroup, "Modify", "Allow")
        Write-Host "Add permissions usergroup"
        $acl.SetAccessRule($accessUserGroup)

        #add CREATOR OWNER with modify rights and add rule to avdStore root including inheritance.
        $accessOwner = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
        Write-Host "Add permissions OWNER"
        $acl.SetAccessRule($accessOwner)

        #Remove BUILTIN\Users permissions
        Write-Host "remove BUILTINUsers permissions"
        ($acl.Access) | Where-Object IdentityReference -EQ "BUILTIN\Users" | ForEach-Object { $acl.RemoveAccessRule($_) }

        #Remove Authenticated Users permissions
        Write-Host "remove Authenticated Users permissions"
        ($acl.Access) | Where-Object IdentityReference -EQ "NT AUTHORITY\Authenticated Users" | ForEach-Object { $acl.RemoveAccessRule($_) }

        #Apply Changes
        Write-Host "Update ACL"
        $acl | Set-Acl avdStore:

        Write-Host "Remove Drive"
        Remove-PSDrive -Name avdStore
        $Cred = $null
        $account = $null
        Remove-Variable Cred
        Remove-Variable account
    }
    else {
        Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
    }
    Write-Host "NTFS Permissions set"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

