<#
@author: cs2099713
@date: 2023-03-26
#>
#Set as Automation Account Variable!
# $CaptureMasterVM = "VMDEAPP01CC123"
# $CaptureMasterCloneSize = "Standard_D4s_v5"

<#
-----------------------------------------------------------------------
Connection
-----------------------------------------------------------------------
#>
$timer = [system.diagnostics.stopwatch]::startNew()

try {
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
-----------------------------------------------------------------------
Get Master VM Data
-----------------------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Get Master VM Data"
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
    $MasterVMNic = Get-AzNetworkInterface -Name $AVDMasterNic.Name -ResourceGroupName $AVDMasterNic.ResourceGroupName
    Write-Output "Collect network data..."
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
    $CloneName = ($masterVM.name.Substring(0, 10) + "C" + $randomString)
    #Generate snapshot name
    $snapshotName = $masterVM.name + "_" + $(Get-Date -Format "yyyy-MM-dd_HH-mm") + "_PreImagaging"
    #Generate clone nic name
    $i = 1
    $nicSuffix = '{0:d3}' -f $i
    $nicName = "nic-$($CloneName.ToLower())-$($nicSuffix)"
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
        CloneName         = $CloneName
        SnapshotName      = $snapshotName
        CloneOSDiskName   = "$($CloneName)_OsDisk"
        CloneNicName      = $nicName
    }
    Write-Output "Done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Cluster VM:"
    Write-Output $ClusterMaster
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
}
catch {
    Write-Output "FAILED in Phase: Get Master VM Data"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}
<#
-----------------------------------------------------------------------
Generate Clone
-----------------------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Generate Clone"
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
    #Disk creation
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
    $ClonedMaster = Get-AzVM -Name $ClusterMaster.CloneName
    Write-Output "Cloning done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Cloned VM:"
    Write-Output $ClonedMaster
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
}
catch {
    Write-Output "FAILED in Phase: Generate Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}
<#
-----------------------------------------------------------------------
Sysprep Cloned Master
-----------------------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"cmd
Write-Output "Sysprep Cloned Master"
Write-Output "-----------------------------------------------------------------------"
try {
    #define sysprep command as AzExtension
    $protectedSettings = @{"commandToExecute" = "C:\Windows\System32\Sysprep\sysprep.exe /quiet /generalize /oobe /shutdown /mode:vm" }

    #Get actual state of cloned vm
    $CloneVmState = (Get-AzVM -ResourceGroupName $ClonedMaster.ResourceGroupName -name $ClonedMaster.Name -Status).Statuses[1].Code

    #Set Az Extension with -NoWait for instant execution
    Set-AzVMExtension -ResourceGroupName $ClonedMaster.ResourceGroupName `
        -Location $ClonedMaster.Location `
        -VMName $ClonedMaster.Name `
        -Name "RunSysprep"`
        -Publisher Microsoft.Compute `
        -ExtensionType CustomScriptExtension `
        -TypeHandlerVersion "1.10" `
        -ProtectedSettings $protectedSettings `
        -NoWait
    $vmStateStoppedOrDeallocated = (($CloneVmState -eq "PowerState/stopped") -or ($CloneVmState -eq "PowerState/deallocated"))
    $waittime = 30
    $lastCloneVmState = ""
    #Query every <waittime> seconds if state change occurs.
    while (!$vmStateStoppedOrDeallocated) {
        if ($lastCloneVmState -ne $CloneVmState) {
            Write-Output "$($ClonedMaster.Name) actual state: $($CloneVmState)"
            Write-Output "$($ClonedMaster.Name) previous state: $($lastCloneVmState)"
        }
        #Update last state with actual state for further comparison.
        $lastCloneVmState = $CloneVmState
        Write-Output "Waiting $($waittime) seconds for status change..."
        $vmstatus = (Get-AzVM -ResourceGroupName $ClonedMaster.ResourceGroupName -name $ClonedMaster.Name -Status)
        Write-Output $vmstatus
        Start-Sleep -Seconds $waittime
        $CloneVmState = (Get-AzVM -ResourceGroupName $ClonedMaster.ResourceGroupName -name $ClonedMaster.Name -Status).Statuses[1].Code
        $vmStateStoppedOrDeallocated = (($CloneVmState -eq "PowerState/stopped") -or ($CloneVmState -eq "PowerState/deallocated"))
    }
    $CloneVmState = (Get-AzVM -ResourceGroupName $ClonedMaster.ResourceGroupName -name $ClonedMaster.Name -Status).Statuses[1].Code
    #deallocates because sysprep usually just stops vm
    if ($CloneVmState -eq "PowerState/stopped") {
        Write-Output "$($ClonedMaster.Name) sysprep complete. Deallocating..."
        Stop-AzVM -Name $ClonedMaster.Name -ResourceGroupName $ClonedMaster.ResourceGroupName -Force
    }
    #generalize vm
    Write-Output "$($ClonedMaster.Name) deallocated. Generalizing VM..."
    Set-AzVm -Name $ClonedMaster.Name -ResourceGroupName $ClonedMaster.ResourceGroupName -Generalized
    Write-Output "$($ClonedMaster.Name) generalization done!"

}
catch {
    Write-Output "FAILED in Phase: Sysprep Cloned Master"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------------------
Publish Image to Gallery
-----------------------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Publish Image to Gallery"
Write-Output "-----------------------------------------------------------------------"

try {
    <#
    Hierarchy within image Gallery:
        Image Gallery
            -> Image Definition
                -> Image Versions
    #>


    #Update ClonedMaster Variable with generalized vm.
    $ClonedMaster = Get-AzVM -Name $ClusterMaster.CloneName
    $ClonedMasterHyperVGen = Get-AzVM -Name $ClusterMaster.CloneName -ResourceGroupName  $ClusterMaster.ResourceGroupName -Status | Select-Object -ExpandProperty HyperVGeneration
    #generate imageName
    $imageName = "img-avd-$(($ClusterMaster.Generation).toLower())-$($TrustedLaunch)-pooled-$(($ClusterMaster.siteCode).toLower())-$(($ClusterMaster.appCode).toLower())-$(($ClusterMaster.locationCode).toLower())-$(($ClusterMaster.environmentType).toLower())"
    #Get Image Gallery
    $imageGallery = Get-AzGallery -Name "gal_avd_shared_$($ClusterMaster.locationCode)_$($ClusterMaster.environmentType)"

    #Try to get image definition (if existing)
    $imageDefinition = Get-AzGalleryImageDefinition -GalleryName $imageGallery.Name -Name $imageName -ResourceGroupName $imageGallery.ResourceGroupName -ErrorAction SilentlyContinue
    $PublisherName = "LEWA"
    #ImageDefinition handling
    if (!$imageDefinition) {
        #Image does not exist, Create Image Gallery Definition
        Write-Output "No Image definition found. Create Image Definition $($imageName)"
        if ($TrustedLaunch -eq "notl") {
            #No trusted launch
            $imageDefinition = New-AzGalleryImageDefinition `
                -GalleryName $imageGallery.Name `
                -ResourceGroupName $imageGallery.ResourceGroupName `
                -Location $imageGallery.Location `
                -Name $imageName `
                -OsType Windows `
                -OsState generalized `
                -Publisher $PublisherName `
                -Offer "$(($ClusterMaster.environmentType).toUpper())-$(($ClusterMaster.locationCode).toUpper())" `
                -Sku "$(($ClusterMaster.siteCode).toUpper())-$(($ClusterMaster.appCode).toUpper())"  `
                -HyperVGeneration $ClonedMasterHyperVGen
        }
        else {
            #With trusted launch
            $SecurityTypeFeature = @{Name = 'SecurityType'; Value = 'TrustedLaunch' }
            $imageFeature = @($SecurityTypeFeature)
            #Create image definition
            $imageDefinition = New-AzGalleryImageDefinition `
                -GalleryName $imageGallery.Name `
                -ResourceGroupName $imageGallery.ResourceGroupName `
                -Location $imageGallery.Location `
                -Name $imageName `
                -OsType Windows `
                -OsState generalized `
                -Publisher $PublisherName `
                -Offer "$(($ClusterMaster.environmentType).toUpper())-$(($ClusterMaster.locationCode).toUpper())"  `
                -Sku "$(($ClusterMaster.siteCode).toUpper())-$(($ClusterMaster.appCode).toUpper())"  `
                -HyperVGeneration $ClonedMasterHyperVGen `
                -Tag $ClusterMaster.Tags
            -Feature $imageFeature
        }
        Write-Output "Image Definition $($imageName) created."
    }
    #Get all image versions of image definiton.
    $imageVersion = Get-AzGalleryImageVersion `
        -ResourceGroupName $imageGallery.ResourceGroupName `
        -GalleryName $imageGallery.Name `
        -GalleryImageDefinitionName $imageDefinition.Name | Sort-Object { $_.PublishingProfile.PublishedDate }
    #Create first image version if no image version exists
    if ($null -eq $imageVersion) {
        $nextVersion = [version]::New(0, 0, 1)
    }
    else {
        #Get latest image version, if image versions exist.
        $latestImageVersion = [version]$imageVersion[-1].Name
        switch ($latestImageVersion) {
            { $_.Build -eq 9 } {
                $nextVersion = [version]::New($_.Major, $_.Minor + 1, 0)
            }
            { $_.Minor -eq 9 } {
                $nextVersion = [version]::New($_.Major + 1, 0, 0)
            }
            default {
                $nextVersion = [version]::New($_.Major, $_.Minor, $_.Build + 1)
            }
        }

    }
    #No Image Replication!
    $GalleryRegion1 = @{Name = $($imageGallery.Location); ReplicaCount = 1 }
    $TargetRegions = @($GalleryRegion1)
    Write-Output "-------------------------------------------------"
    Write-Output "New Image:"
    Write-Output "`tGallery:`t$($imageGallery.Name)"
    Write-Output "`tImage:`t`t$($imageDefinition.Name)"
    Write-Output "`tVersion:`t$($nextVersion)"
    Write-Output "`tPublisher:`t$($imageDefinition.Identifier.Publisher)"
    Write-Output "`tOffer:`t`t$($imageDefinition.Identifier.Offer)"
    Write-Output "`tSKU:`t`t$($imageDefinition.Identifier.Sku)"
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    try {
        $timer2 = [system.diagnostics.stopwatch]::startNew()
        Write-Output "Start image publishing. This can take long (>15 Minutes)"
        $imagingJob = $tempImageVersion = New-AzGalleryImageVersion `
            -ResourceGroupName $imageGallery.ResourceGroupName `
            -GalleryName $imageGallery.Name `
            -GalleryImageDefinitionName $imageDefinition.Name `
            -Name $nextVersion `
            -Location $imageGallery.Location `
            -SourceImageId $ClonedMaster.Id `
            -ReplicaCount 1 `
            -TargetRegion $TargetRegions `
            -Tag $ClusterMaster.Tags `
            -asJob

        Write-Output "---waiting---"
        while ($imagingJob.State -eq "Running") {
            $waitSeconds = 60
            Write-Output "Publishing Runtime Elapsed: $($timer2.Elapsed.toString())"
            Write-Output "Wait another $($waitSeconds) seconds..."
            Start-Sleep -Seconds $waitSeconds
        }
        Write-Output "---"
        $timer2.stop()
        Write-Output "Total Publishing Runtime: $($timer2.Elapsed.toString())"
        Write-Output "Runtime: $($timer.Elapsed.toString())"
    }
    catch {
        $timer2.stop()
        Write-Output "Total Publishing Runtime till failure: $($timer2.Elapsed.toString())"
        Write-Output "-------------------------------------------------"
        Write-Output "Image publishing failed!"
        Write-Output "-------------------------------------------------"
        Write-Output "Runtime: $($timer.Elapsed.toString())"
    }

}
catch {
    Write-Output "FAILED in Phase: Publish Image to Gallery"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------------------
Resource Cleanup
-----------------------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Resource Cleanup"
Write-Output "-----------------------------------------------------------------------"
try {
    #("AVDClusterClone","True")
    #("ClonedSrc",($ClusterMaster.Name))
    $resoucesToCleanup = (Get-AzResource | Where-Object { ($_.Tags.AVDClusterClone -eq "True") -and ($_.Tags.ClonedSrc -eq ($ClusterMaster.Name)) -and ($_.Name -ne $ClonedMaster.Name) }) | Sort-Object { $_.Length }
    $failedRemoval = @()

    $resoucesToCleanup | Where-Object {}

    #delete cloneVM first
    try {
        Remove-AzResource -ResourceId $ClonedMaster.id -Force
        Write-Output "$($ClonedMaster.Name) successfully removed!"
    }
    catch {
        Write-Output "Failed to remove $($ClonedMaster.Name)"
        $failedRemoval += $ClonedMaster
    }

    foreach ($resource in $resoucesToCleanup) {
        Write-Output "Remove temporary resource: $($resource.Name)"
        try {
            Remove-AzResource -ResourceId $resource.Id -Force
            Write-Output "$($resource.Name) successfully removed!"
            Start-Sleep -Seconds 120
        }
        catch {
            Write-Output "Failed to remove $($resource.Name)"
            $failedRemoval += $resource
        }
        Write-Output "-----------------------------------------------------------------------"
        Write-Output "Runtime: $($timer.Elapsed.toString())"
    }
    Write-Output "Finishing..."
    if ($failedRemoval.Count -gt 0) {
        Write-Output "Failed to remove following resources:"
        foreach ($failed in $failedRemoval) {
            Write-Output "`tName:`t`t`t$($failed.name)"
            Write-Output "`tResourceGroup:`t`t$($failed.ResourceGroupName)"
            Write-Output "`tResourceType:`t`t$($failed.ResourceType)"
            Write-Output "`tSubscription:`t`t$($azContext.Subscription.Name)"
            Write-Output "`tResource Id:`t`t$($failed.Id)"
            Write-Output "-----------------------------------------------------------------------"
        }
    }
    Write-Output "-----------------------------------------------------------------------"
    Write-Output "Finished!"
    Write-Output "-----------------------------------------------------------------------"
    $timer.stop()
    Write-Output "Total Execution Time:"
    Write-Output $timer.elapsed
    Write-Output "Formatted`t  : $($timer.elapsed.ToString())"



}
catch {
    Write-Output "FAILED in Phase: Resource Cleanup"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}