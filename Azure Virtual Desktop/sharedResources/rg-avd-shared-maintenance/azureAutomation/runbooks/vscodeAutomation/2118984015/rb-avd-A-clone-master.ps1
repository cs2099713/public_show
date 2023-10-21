#Author: cs2099713
#Date: 29.03.2023

<#
-----------------------------------------------------------
|||||||||||||||  Step 0:  Connect to Azure  |||||||||||||||
-----------------------------------------------------------
> VARIABLES:
> - $azContext
> - $CaptureMasterCloneSize
> - $CaptureMasterVM
> - $timer
-----------------------------------------------------------
#>
#Debugging Start
#    $CaptureMasterVM = "VMDEAPP01M"
#$CaptureMasterCloneSize = "Standard_D4s_v5"
# Debugging End

try {
    $timer = [system.diagnostics.stopwatch]::startNew()
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "Connection"
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
    Write-Output Get-AzContext
    $azContext = Get-AzContext
    Write-Output "Connected to"
    Write-Output "`tTenant:`t`t`t`t$($azContext.subscription.TenantId)"
    Write-Output "`tSubscription Id:`t$($azContext.subscription.Id)"
    Write-Output "`tSubscription Name:`t$($azContext.subscription.Name)"
    Write-Output "-------------------------------------------------"
    Write-Output "Get Automation Account Variables:"
    $CaptureMasterCloneSize = Get-AutomationVariable -Name CaptureMasterCloneSize
    Write-Output "`tCaptureMasterCloneSize set to:`t$($CaptureMasterCloneSize)"
    $CaptureMasterVM = Get-AutomationVariable -Name CaptureMasterVM
    Write-Output "`tCaptureMasterVM set to:`t`t`t$($CaptureMasterVM)"
    Write-Output "Runtime: $($timer.Elapsed.toString())"



}
catch {
    Write-Output "FAILED in Phase: Connection"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}


<#
-----------------------------------------------------------
|||||||||  Step 1: Gather Cluster Master Details  |||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 1: Gather Cluster Master Details"
Write-Output "-----------------------------------------------------------------------"
try {
    Write-Output "Collect vm data..."
    #Get master vm as type [AzResource] for resource ID
    $AVDMaster = Get-AzResource `
        -ResourceType "Microsoft.Compute/virtualMachines" `
        -ResourceName $CaptureMasterVM
    #Get master vm as type [AzVM] for attributes
    $masterVM = Get-AzVM `
        -Name $AVDMaster.Name `
        -resourcegroupname $AVDMaster.resourceGroupName
    #Get master vm generation as string
    $masterVMGen = Get-AzVM `
        -Name $AVDMaster.Name `
        -ResourceGroupName $AVDMaster.resourceGroupName `
        -Status | Select-Object `
        -ExpandProperty HyperVGeneration
    Write-Output "Collect os disk data..."
    #Get master attributes for disk
    $masterVmOsDisk = Get-AzDisk -DiskName $masterVM.StorageProfile.OsDisk.Name
    Write-Output "Collect nic data..."
    #Get master vm nic as type [AzResource] by resource ID
    $AVDMasterNic = Get-AzResource -ResourceId $masterVM.NetworkProfile.NetworkInterfaces.id
    #Get master vm nic as type [AzNetworkInterface]
    Write-Output "Collect network data..."
    $MasterVMNic = Get-AzNetworkInterface -Name $AVDMasterNic.Name -ResourceGroupName $AVDMasterNic.resourceGroupName
    #Get master vm subnet as type [AzResource] by resource ID
    $AVDMasterSubnet = Get-AzResource -ResourceId $MasterVMNic.IpConfigurations[0].Subnet.id
    #Get master vm vnet as type [AzVirtualNetwork]
    $MasterVMvnet = Get-AzVirtualNetwork -name (($AVDMasterSubnet.Id -split '/')[-3]) -resourcegroupname $AVDMasterSubnet.resourceGroupName
    #Get master vm subnet as type [AzVirtualNetworkSubnetConfig]
    $MasterVMSubnet = Get-AzVirtualNetworkSubnetConfig -name $AVDMasterSubnet.Name -VirtualNetwork $MasterVMvnet
    Write-Output "Generate naming for clone..."
    #Generate Random 3 character string for clone name
    $alphabet = [Char[]] 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $randomString = (Get-Random -Count 3 -InputObject $alphabet) -join ''
    $GenCloneName = ($masterVM.name.Substring(0, 10) + "C" + $randomString)
    #Check for Automation Variable
    #    Set-AutomationVariable -Name $GenCloneName
    #Generate snapshot name
    $snapshotName = $masterVM.name + "_" + $(Get-Date -Format "yyyy-MM-dd_HH-mm") + "_PreImagaging"
    #Generate clone nic name
    $i = 1
    $nicSuffix = '{0:d3}' -f $i
    $nicName = "nic-$($GenCloneName.ToLower())-$($nicSuffix)"
    $ClusterMaster = [PSCustomObject]@{
        Name              = $masterVM.name
        Id                = $AVDMaster.id
        ResourceGroupName = $AVDMaster.ResourceGroupName
        SubscriptionId    = $azContext.subscription.Id
        SubscriptionName  = $azContext.subscription.Name
        OSDisk            = $masterVmOsDisk
        Generation        = $masterVMGen
        SecurityProfile   = $masterVM.SecurityProfile
        nic               = $MasterVMNic
        vNet              = $MasterVMvnet
        subNet            = $MasterVMSubnet
        Location          = $AVDMaster.Location
        environmentType   = $MasterVMSubnet.name.Split("-")[6].ToLower()
        locationCode      = $MasterVMSubnet.name.Split("-")[5].ToLower()
        siteCode          = $MasterVMSubnet.name.Split("-")[2].ToLower()
        appCode           = $MasterVMSubnet.name.Split("-")[3].ToLower()
        Tags              = $AVDMaster.Tags
        "---"             = "------------------------------------------------------------"
        CloneName         = $GenCloneName
        SnapshotName      = $snapshotName
        CloneOSDiskName   = "$($GenCloneName)_OsDisk"
        CloneNicName      = $nicName
    }
    Write-Output "Done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Cluster VM:"
    Write-Output $ClusterMaster
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"
}
catch {
    Write-Output "FAILED in Step 1: Gather Cluster Master Details"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
|||||||  Step 2: Create Snapshot of Master OS Disk  |||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 2: Create Snapshot of Master OS Disk"
Write-Output "-----------------------------------------------------------------------"
try {
    #Prepare Tags for Clone (deep copy!!!)
    $CloneTags = [ordered]@{}
    foreach ($tag in $ClusterMaster.Tags.GetEnumerator()) {
        $CloneTags[$tag.Key] = $tag.Value
    }
    $CloneTags.Add("AVDClusterClone", "True")
    $CloneTags.Add("ClonedSrc", ($ClusterMaster.Name))
    #Snapshot creation
    Write-Output "Creating Snapshot..."
    #->New snapshot config
    $snapshotConfig = New-AzSnapshotConfig `
        -SourceUri $ClusterMaster.OSDisk.id `
        -OsType Windows `
        -CreateOption Copy `
        -Location $ClusterMaster.Location `
        -Tag $ClusterMaster.Tags
    #->New snapshot
    $snapshot = New-AzSnapshot `
        -Snapshot $snapshotConfig `
        -SnapshotName $ClusterMaster.SnapshotName `
        -ResourceGroupName $ClusterMaster.ResourceGroupName
    Write-Output "Snapshot $($snapshot.name) created!"
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"
}
catch {
    Write-Output "FAILED in Step 2: Create Snapshot of Master OS Disk"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
|||||||||||  Step 3: Create Disk from Snapshot  |||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 3: Create Disk from Snapshot"
Write-Output "-----------------------------------------------------------------------"
try {
    Write-Output "Create new OsDisk..."
    #->New Disk Config
    $diskConfig = New-AzDiskConfig  `
        -SourceResourceId $snapshot.Id `
        -CreateOption Copy `
        -Location $ClusterMaster.Location `
        -Tag $CloneTags
    #->New OS Disk
    $osDisk = New-AzDisk `
        -DiskName $ClusterMaster.CloneOSDiskName `
        -Disk $diskConfig `
        -ResourceGroupName $ClusterMaster.ResourceGroupName
    Write-Output "OS Disk $($osDisk.name) created!"
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"
}
catch {
    Write-Output "FAILED in Step 3: Create Disk from Snapshot"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
|||||||||||||  Step 4:  Create NIC for Clone  |||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 4:  Create NIC for Clone"
Write-Output "-----------------------------------------------------------------------"
try {
    #NIC creation
    Write-Output "Create new NIC..."
    #->New NIC
    $networkCard = New-AzNetworkInterface `
        -Name $ClusterMaster.CloneNicName `
        -ResourceGroupName $ClusterMaster.ResourceGroupName `
        -Location $ClusterMaster.Location `
        -Subnet $ClusterMaster.subNet `
        -Tag $CloneTags
    Write-Output "NIC $($networkCard.name) created!"
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"
}
catch {
    Write-Output "FAILED in Step 4:  Create NIC for Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}


<#
-----------------------------------------------------------
||||||||||||  Step 5: Create new VM for Clone  ||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 5: Create new VM for Clone"
Write-Output "-----------------------------------------------------------------------"
try {
    Write-Output "Prepare clone parameters..."
    #Set MachineSize in new VM Config
    $cloneVM = New-AzVMConfig `
        -VMName $ClusterMaster.CloneName `
        -VMSize $CaptureMasterCloneSize `
        -Tags $CloneTags
    #Set NIC
    $cloneVM = Add-AzVMNetworkInterface `
        -VM $cloneVM `
        -Id $networkCard.id
    #Disable Boot Diagnostics
    $cloneVM = Set-AzVMBootDiagnostic `
        -VM $cloneVM `
        -Disable
    #Generation V2 = Trusted Launch & SecureBoot enabled
    if (($ClusterMaster.Generation -eq "V2") -and ($ClusterMaster.SecurityProfile -eq $true)) {
        Write-Output "Master: Gen2 with trusted launch/secureboot"
        #Set Trusted Launch
        $cloneVM = Set-AzVMSecurityProfile `
            -SecurityType "TrustedLaunch" `
            -VM $cloneVM
        #Set Uefi secure boot with TPM
        $VirtualMachine = Set-AzVmUefi `
            -VM $VirtualMachine `
            -EnableVtpm $true `
            -EnableSecureBoot $true
        #for later identification set tl = true
        $TrustedLaunch = "tl"
    }
    else {
        #for later identification, set tl = false
        $TrustedLaunch = "notl"
    }
    #Set Disk
    $cloneVM = Set-AzVMOSDisk -VM $cloneVM -ManagedDiskId $osDisk.Id -CreateOption Attach -StorageAccountType StandardSSD_LRS -DiskSizeInGB $osDisk.DiskSizeGB -Windows
    #Create Clone
    Write-Output "Cloning..."
    New-AzVM `
        -ResourceGroupName $ClusterMaster.ResourceGroupName `
        -Location $ClusterMaster.Location `
        -VM $cloneVM  `
        -Verbose
    Start-Sleep -Seconds 15
    $ClonedMaster = Get-AzVM -Name $ClusterMaster.CloneName
    Write-Output "Cloning done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Cloned VM:"
    Write-Output $ClonedMaster
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"

}
catch {
    Write-Output "FAILED in Step 5: Create new VM for Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
|||||||||||||||||  Step 6: Sysprep Clone  |||||||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 6: Sysprep Clone"
Write-Output "-----------------------------------------------------------------------"
try {
    Write-Output "Please do manually for now. RDP into VM then run in admin cmd"
    Write-Output "C:\Windows\System32\Sysprep\sysprep.exe /quiet /generalize /oobe /shutdown /mode:vm"
    Write-Output "Once Sysprep is finished, please stop clone for a second time to deallocate resources."
    Write-Output "Then please continue with rb-avd-B-clone-master"
}
catch {
    Write-Output "FAILED in Step 6: Sysprep Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}