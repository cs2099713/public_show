#Author: cs2099713
#Date: 29.03.2023

<#
-----------------------------------------------------------
|||||||||||||||  Step 0:  Connect to Azure  |||||||||||||||
-----------------------------------------------------------
> VARIABLES:
> - $azContext
> - $CloneName
> - $timer
-----------------------------------------------------------
#>
#Debugging Start
#    $CloneName = "VMDEAPP01CC123"
#    $CaptureMasterVM =  "VMDEAPP01M"
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
    $CloneName = Get-AutomationVariable -Name CloneName
    Write-Output "`CloneName set to:`t$($CloneName)"
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
|||||||||||||  Step 1:  Gather Clone Details  |||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 7:  Gather Clone Details"
Write-Output "-----------------------------------------------------------------------"
try {
    Write-Output "Collect vm data..."
    #Get clone vm as type [AzVM] for attributes
    $cloneVM = Get-AzVM `
        -Name $CloneName #`
    #-resourcegroupname $AVDclone.resourceGroupName
    #Get clone vm as type [AzResource] for resource ID
    $AVDclone = Get-AzResource `
        -ResourceType "Microsoft.Compute/virtualMachines" `
        -ResourceName $cloneVM.Name `
        -ResourceGroupName $cloneVM.ResourceGroupName
    #Get clone vm generation as string
    $cloneVMGen = Get-AzVM `
        -Name $AVDclone.Name `
        -ResourceGroupName $AVDclone.resourceGroupName `
        -Status | Select-Object `
        -ExpandProperty HyperVGeneration
    Write-Output "Collect os disk data..."
    #Get clone attributes for disk
    $cloneVmOsDisk = Get-AzDisk -DiskName $cloneVM.StorageProfile.OsDisk.Name
    Write-Output "Collect nic data..."
    #Get clone vm nic as type [AzResource] by resource ID
    $cloneNic = Get-AzResource -ResourceId $cloneVM.NetworkProfile.NetworkInterfaces.id
    #Get clone vm nic as type [AzNetworkInterface]
    $cloneVMNic = Get-AzNetworkInterface -Name $cloneNic.Name -ResourceGroupName $cloneNic.ResourceGroupName
    Write-Output "Collect network data..."
    #Get clone vm subnet as type [AzResource] by resource ID
    $AVDCloneSubnet = Get-AzResource -ResourceId $cloneVMNic.IpConfigurations[0].Subnet.id
    #Get clone vm vnet as type [AzVirtualNetwork]
    $CloneVMvnet = Get-AzVirtualNetwork -name (($AVDCloneSubnet.Id -split '/')[-3]) -resourcegroupname $AVDCloneSubnet.resourceGroupName
    #Get clone vm subnet as type [AzVirtualNetworkSubnetConfig]
    $CloneVMSubnet = Get-AzVirtualNetworkSubnetConfig -name $AVDCloneSubnet.Name -VirtualNetwork $CloneVMvnet
    $ClonedMachine = [PSCustomObject]@{
        Name              = $cloneVM.name
        Id                = $AVDclone.id
        ResourceGroupName = $AVDclone.ResourceGroupName
        SubscriptionId    = $azContext.subscription.Id
        SubscriptionName  = $azContext.subscription.Name
        OSDisk            = $cloneVmOsDisk
        Generation        = $cloneVMGen
        SecurityProfile   = $cloneVM.SecurityProfile
        nic               = $cloneVMNic
        vNet              = $CloneVMvnet
        subNet            = $AVDCloneSubnet
        Location          = $AVDclone.Location
        environmentType   = $CloneVMSubnet.name.Split("-")[6].ToLower()
        locationCode      = $CloneVMSubnet.name.Split("-")[5].ToLower()
        siteCode          = $CloneVMSubnet.name.Split("-")[2].ToLower()
        appCode           = $CloneVMSubnet.name.Split("-")[3].ToLower()
        Tags              = $cloneVM.Tags
    }
    Write-Output "Done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Cloned VM:"
    Write-Output $ClonedMachine
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"

}
catch {
    Write-Output "FAILED in Step 1:  Gather Clone Details"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}
<#
-----------------------------------------------------------
|||||||||||||||  Step 2:  Generalize Clone  |||||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 8:  Generalize Clone"
Write-Output "-----------------------------------------------------------------------"

try {

    $ClonedMaster = Get-AzVM -Name $ClonedMachine.Name -ResourceGroupName "rg-avd-shared-master-$($ClonedMachine.locationCode)-$($ClonedMachine.environmentType)"
    $CloneVmState = (Get-AzVM -ResourceGroupName $($ClonedMaster.ResourceGroupName) -name $($ClonedMaster.Name) -Status).Statuses[1].Code
    #deallocates because sysprep usually just stops vm
    if ($CloneVmState -eq "PowerState/stopped") {
        Write-Output "Deallocating $($ClonedMaster.Name)..."
        Stop-AzVM -Name $ClonedMaster.Name -ResourceGroupName $ClonedMaster.ResourceGroupName -Force
        Write-Output "$($ClonedMaster.Name) deallocated."
    }
    else {
        $out = Get-AzVm -Name $($ClonedMaster.Name) -ResourceGroupName $($ClonedMaster.ResourceGroupName) -Status
        Write-Output $out
        Write-Output "$($ClonedMaster.Name) already deallocated."
        $out = $null
    }
    #Generalize
    Write-Output "$($ClonedMaster.Name) Generalizing VM..."
    Set-AzVm -Name $($ClonedMaster.Name) -ResourceGroupName $($ClonedMaster.ResourceGroupName) -Generalized
    Write-Output "$($ClonedMaster.Name) generalization done!"
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"
}
catch {
    Write-Output "FAILED in Step 8:  Generalize Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
||||||||||||  Step 9:  Create Image Definition  |||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 9:  Create Image Definition"
Write-Output "-----------------------------------------------------------------------"

try {
    #Get Image Gallery
    Write-Output "Get Image Gallery"
    $imageGallery = Get-AzGallery -Name "gal_avd_shared_$($ClonedMachine.locationCode)_$($ClonedMachine.environmentType)"
    #Set TrustedLaunch variable
    if (($ClonedMachine.Generation -eq "V2") -and ($ClonedMachine.SecurityProfile -eq $true)) {
        $TrustedLaunch = "tl"
    }
    else {
        $TrustedLaunch = "notl"
    }

    #Generate image name
    Write-Output "Generate Image Name"
    $imageName = "img-avd-$(($ClonedMachine.Generation).toLower())-$($TrustedLaunch)-pooled-$(($ClonedMachine.siteCode).toLower())-$(($ClonedMachine.appCode).toLower())-$(($ClonedMachine.locationCode).toLower())-$(($ClonedMachine.environmentType).toLower())"
    #Try to get image definition (if existing)
    Write-Output "Try to get Image definition"
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
                -Offer "$(($ClonedMachine.environmentType).toUpper())-$(($ClonedMachine.locationCode).toUpper())" `
                -Sku "$(($ClonedMachine.siteCode).toUpper())-$(($ClonedMachine.appCode).toUpper())"  `
                -HyperVGeneration $($ClonedMachine.Generation)
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
                -Offer "$(($ClonedMachine.environmentType).toUpper())-$(($ClonedMachine.locationCode).toUpper())"  `
                -Sku "$(($ClonedMachine.siteCode).toUpper())-$(($ClonedMachine.appCode).toUpper())"  `
                -HyperVGeneration $($ClonedMachine.Generation) `
                -Tag $ClonedMachine.Tags `
                -Feature $imageFeature
        }
        Write-Output "Image Definition $($imageName) created."
    }
    else {
        Write-Output "Image Definition $($imageName) exists."
    }
    Write-Output "-------------------------------------------------"
    Write-Output "Runtime: $($timer.Elapsed.toString())"
    Write-Output "-------------------------------------------------"

}
catch {
    Write-Output "FAILED in Step 9:  Create Image Definition"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
|||||||||||  Step 10:  Create and Publish Image  ||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 10:  Create and Publish Image"
Write-Output "-----------------------------------------------------------------------"

try {
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
    Write-Output "`tGalleryRG:`t$($imageGallery.ResourceGroupName)"
    Write-Output "`tImage:`t`t$($imageDefinition.Name)"
    Write-Output "`tVersion:`t$($nextVersion)"
    Write-Output "`tPublisher:`t$($imageDefinition.Identifier.Publisher)"
    Write-Output "`tOffer:`t`t$($imageDefinition.Identifier.Offer)"
    Write-Output "`tSKU:`t`t$($imageDefinition.Identifier.Sku)"
    Write-Output "-------------------------------------------------"
    try {
        $timer2 = [system.diagnostics.stopwatch]::startNew()
        Write-Output "Start image publishing. This can take long (>15 Minutes)"
        $imagingJob = $tmpimgjb = New-AzGalleryImageVersion `
            -ResourceGroupName $imageGallery.ResourceGroupName `
            -GalleryName $imageGallery.Name `
            -GalleryImageDefinitionName $imageDefinition.Name `
            -Name $nextVersion `
            -Location $imageGallery.Location `
            -SourceImageId $ClonedMaster.Id `
            -ReplicaCount 1 `
            -TargetRegion $TargetRegions `
            #-Tag $ClusterMaster.Tags `
            -asJob

        Write-Output "---waiting---"
        Start-Sleep -s 10
        while ($imagingJob.State -eq "Running") {
            $waitSeconds = 60
            $newestVersion = (Get-AzGalleryImageVersion -ResourceGroupName $imd.ResourceGroupName -GalleryName $g.Name -GalleryImageDefinitionName $imd.Name) | Select-Object * -ExpandProperty PublishingProfile | Sort-Object PublishedDate -Descending | Select-Object Name, ProvisioningState, PublishedDate -First 1
            Write-Output "Publishing Runtime Elapsed: $($timer2.Elapsed.toString())"
            Write-Output "Newest Version:"
            Write-Output "..........................................."
            Write-Output $newestVersion
            Write-Output "..........................................."
            Write-Output "Wait another $($waitSeconds) seconds..."
            Write-Output "..........................................."
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
        Write-Output "-------------------------------------------------"
    }

}
catch {
    Write-Output "FAILED in Step 10:  Create and Publish Image"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}

<#
-----------------------------------------------------------
||||||||||||||||  Step 10:  Cleanup Clone  ||||||||||||||||
-----------------------------------------------------------
#>
Write-Output "-----------------------------------------------------------------------"
Write-Output "Step 10:  Cleanup Clone"
Write-Output "-----------------------------------------------------------------------"

try {
    $resoucesToCleanup = (Get-AzResource | Where-Object { ($_.Tags.AVDClusterClone -eq "True") -and ($_.Tags.ClonedSrc -eq ($CaptureMasterVM)) -and ($_.Name -ne $ClonedMaster.Name) }) | Sort-Object { $_.Length }
    <#
    try {
        # Remove VM first
        $removeCloneJob = Remove-AzResource -ResourceId $ClonedMaster.id -Force -AsJob
        Write-Output "Remove Clone VM first..."
        while ($removeCloneJob.State -eq "Running") {
            Write-Output "Remove VM job state: $($removeCloneJob.State)"
            Write-Output "Wait 10 seconds..."
            Start-Sleep -Seconds 10
        }
        Write-Output "$($ClonedMaster.Name) successfully removed!"
        Write-Output "-------------------------------------------------"
        Write-Output "Runtime: $($timer.Elapsed.toString())"
        Write-Output "-------------------------------------------------"
        # After VM removal, remove disk and nic.
        try {
            foreach ($resource in $resoucesToCleanup) {
                Write-Output "Remove temporary resource: $($resource.Name)"
                $resourceRemoval = Remove-AzResource -ResourceId $resource.Id -Force -AsJob
                while ($resourceRemoval.State -eq "Running") {
                    Write-Output "Removal of $($resource.Name) job state: $($resourceRemoval.State)"
                    Write-Output "Wait 10 seconds..."
                    Start-Sleep -Seconds 10
                }
                Write-Output "$($resource.Name) successfully removed!"
                Write-Output "-------------------------------------------------"
                Write-Output "Runtime: $($timer.Elapsed.toString())"
                Write-Output "-------------------------------------------------"
            }
        }
        catch {
            Write-Output "$($resource.Name) removal FAILED!"
            Write-Output "Skipping resource removal."
            Write-Error -Message "$($resource.Name) removal FAILED! Skipped Removal"
        }
    }
    catch {
        Write-Output "$($ClonedMaster.Name) removal FAILED!"
        Write-Output "Skipping resource removal."
        Write-Error -Message "$($ClonedMaster.Name) removal FAILED! Skipped Removal"
    }#>
}
catch {
    Write-Output "FAILED in Step 10:  Cleanup Clone"
    $timer.stop()
    Write-Output $timer.elapsed
    Write-Error -Message $_.Exception
    throw $_.Exception
}