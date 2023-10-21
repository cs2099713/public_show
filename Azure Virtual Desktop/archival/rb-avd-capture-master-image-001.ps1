<#
<#--------- Tags required ---------#>
<#
AVD_ImageCapture_Enabled = "True"
AVD_ImageCapture_TargetGalleryName = ""
AVD_ImageCapture_Subnet = ""
AVD_Global_Workload = "Individual"
AVD_Global_HostpoolType = "Personal"

For manual testing use:
Connect-AzAccount -Tenant "abcdef-1234-1234-abcd-abcdef123456"
Set-AzContext -Subscription "abcdef-1234-1234-defg-abcdef123456"

#>

# Sign in to your Azure subscription
try {
	"Logging in to Azure..."
	Connect-AzAccount -Identity
}
catch {
	Write-Error -Message $_.Exception
	throw $_.Exception
}

#$TenantId = "abcdef-1234-1234-abcd-abcdef123456"
#Connect-AzAccount -TenantId $TenantId

## Function
function Tag-Resource() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceName,
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        [Parameter(Mandatory = $true)]
        $Tags = @{}
    )

	write-output "ResourceName: $ResourceName" # added by cko
	write-output "ResourceGroup: $ResourceGroup" # added by cko
	write-output "Tags: $($Tags| Out-String)" # added by cko

	try
	{
		Start-Sleep -Seconds 5 # added by cko - without sleep it could happen that the following step of Get-AzResource creates an error
		$azResource = Get-AzResource -ResourceGroupName $ResourceGroup -Name $ResourceName
		#write-output "azResource:" $azResource # added by cko
		write-output "azResource Resource Type: $($azResource."ResourceType")" # added by cko
		#$azResource.Tags.Add($Tags)
		#$azResource | Set-AzResource -Force
		$newTags = $azResource.Tags
		$newTags += $Tags
		Set-AzResource -ResourceGroupName $ResourceGroup -Name $ResourceName -ResourceType $azResource.ResourceType -Tag $newTags -Confirm:$false -Force

		write-output "Successfully tagged resource $ResourceName in resource group $ResourceGroup"
		write-output $newTags
	}
	catch
	{
		write-output "Failed to tag resource $ResourceName in resource group $ResourceGroup"
	}
}

## Main Job definition
$jobTaskName = "Capture"
$jobTags = @{WVDJob = "$jobTaskName" } ## Add tags syntax @{tag1="value1";tag2="value2"} / Hashtable
$jobTempTags = $jobTags + @{WVDTemp = "$true" } ## Add tags syntax @{tag1="value1";tag2="value2"} / Hashtable

$jobCompleteTags = @{AVD_ImageCapture_Enabled = "False" }

$wvdVMSize = "Standard_D4s_v5"
$azVMNicPrefix = "nic"

## Getting the Master VM Name from the Azure resource with Tag WVD Master set to environment id
#$varWvdMasterVMName = Get-AzResource -ResourceType "Microsoft.Compute/VirtualMachines" | Where-Object {($_.Tags.WVDMaster -eq "$wvdIsWVDMaster") -and ($_.Tags."AVD_Global_OSBuild" -eq "$wvdVMImgBuild") -and ($_.Tags."AVD_Global_HostpoolID" -eq "$wvdVMHostpoolId")} | Select-Object -ExpandProperty Name
#$varAvdMasterVMs = Get-AzResource -ResourceType "Microsoft.Compute/VirtualMachines" | Where-Object { $_.Tags."AVD_ImageCapture_Enabled" -eq "True" } 	# Tags get by this method are not up-to-date when they were changed in the Azure portal manually before

$varAvdMasterVMs = Get-AzResource -ResourceType "Microsoft.Compute/VirtualMachines" -TagName "AVD_ImageCapture_Enabled" #added by cko
Write-Output $varAvdMasterVMs

Foreach ($varAvdMasterVM in $varAvdMasterVMs)
{
	$tags = Get-AzTag -ResourceId $varAvdMasterVM.id #added by cko
	if ($tags.Properties.TagsProperty."AVD_ImageCapture_Enabled" -eq "True") #added by cko
	{
		## Get required values for image capture
		$varAvdMasterVMName = $varAvdMasterVM | Select-Object -ExpandProperty Name
		Write-Output "Master VM $varWvdMasterVMName found."

		$varAvdMasterRscGroup = $varAvdMasterVM.ResourceGroupName
		#$varAvdACGName = $varAvdMasterVM.Tags."AVD_ImageCapture_TargetGalleryName" 	# Tags get by this method are not up-to-date when they were changed in the Azure portal manually before
		$varAvdACGName = $tags.Properties.TagsProperty."AVD_ImageCapture_TargetGalleryName"
		$varAvdImageRscGroup = Get-AzResource -Name $varAvdACGName -ResourceType "Microsoft.Compute/galleries" | Select-Object -ExpandProperty ResourceGroupName

		#added by cko
		$tags = Get-AzTag -ResourceId $varAvdMasterVM.id
		#$varAvdMasterVMWorkload = $tags.Properties.TagsProperty."AVD_Global_Workload".ToLower()
		#$varAvdMasterVMWorkload = $tags.Properties.TagsProperty."AVD_Global_Workload"
		#$varAvdMasterVMHostpoolType = $tags.Properties.TagsProperty."AVD_Global_HostpoolType".ToLower()
		#$varAvdMasterVMReplicaConfig = $tags.Properties.TagsProperty."AVD_ImageCapture_ReplicaConfig"

		$tagName = "AVD_Global_Workload"

		if($tags.Properties.TagsProperty."$tagName")
		{
			$varAvdMasterVMWorkload = $tags.Properties.TagsProperty."$tagName"
		}
		else
		{
			throw "Missing $tagName tag configuration on Master VM."
		}


		$tagName = "AVD_Global_HostpoolType"

		if($tags.Properties.TagsProperty."$tagName")
		{
			$varAvdMasterVMHostpoolType = $tags.Properties.TagsProperty."$tagName".ToLower()
		}
		else
		{
			throw "Missing $tagName tag configuration on Master VM."
		}

		$tagName = "AVD_ImageCapture_Subnet"

		if($tags.Properties.TagsProperty."$tagName")
		{
			$varAvdMasterVMSubnet = $tags.Properties.TagsProperty."$tagName"
		}
		else
		{
			throw "Missing $tagName tag configuration on Master VM."
		}


		# Tags get by this method are not up-to-date when they were changed in the Azure portal manually before
		<#
		$varAvdMasterVMWorkload = $varAvdMasterVM.Tags."AVD_Global_Workload".ToLower()
		$varAvdMasterVMHostpoolType = $varAvdMasterVM.Tags."AVD_Global_HostpoolType".ToLower()
		$varAvdMasterVMReplicaConfig = $varAvdMasterVM.Tags."AVD_ImageCapture_ReplicaConfig"
		#>

		## Define target Regions from Tag Config
		$targetRegions = @()

		<#$varAvdMasterVMTargetRegions = $varAvdMasterVMReplicaConfig.Split(";")
		Foreach($tr in $varAvdMasterVMTargetRegions)
		{
			$currentRegion = @{Name = $tr.Split("=")[0]; ReplicaCount = $tr.Split("=")[1]}
			$targetRegions += $currentRegion
		}
		#>

		## Get a random number to identify the resources fpr this run
		$randIntNumber = Get-Random -Minimum 100 -Maximum 999

		## Set local variables
		$snapshotName = "$varAvdMasterVMName-$(Get-Date -Format "dd-MM-yyyy-HH-mm")-BS"
		$newVMName = "$($varAvdMasterVMName)-$($randIntNumber)"
		$osDiskName = "$($newVMName)_OSDisk"

		## Logging - Tag Configuration
		Write-Output " "
		Write-Output "--------------------- Tag Configuration - START ------------------------"
		Write-Output "AVD_Global_Workload = $varAvdMasterVMWorkload"
		Write-Output "AVD_Global_HostpoolType = $varAvdMasterVMHostpoolType"
		Write-Output " "
		Write-Output "AVD_ImageCapture_Enabled = True"
		Write-Output "AVD_ImageCapture_Subnet = $varAvdMasterVMSubnet"
		Write-Output "AVD_ImageCapture_TargetGalleryName = $varAvdACGName"
		Write-Output "AVD_ImageCapture_ReplicaConfig = $varAvdMasterVMReplicaConfig"
		Write-Output "--------------------- Tag Configuration - END ------------------------"
		Write-Output " "

		## Logging - Starting Image Capturing Process

		Write-Output " "
		Write-Output "--------------------- Clone Virtual Machine - START ------------------------"

		## Get the VM object
		Write-Output "Getting Azure VM information."
		$newAzVM = Get-AzVM -Name $varAvdMasterVMName `
			-ResourceGroupName $varAvdMasterRscGroup

		## Get the OS disk name
		Write-Output "Getting OS Disk information."
		$newAzDisk = Get-AzDisk -ResourceGroupName $varAvdMasterRscGroup `
			-DiskName $newAzVM.StorageProfile.OsDisk.Name

		## Create the snapshot configuration
		Write-Output "Creating Snapshot Config..."
		$snapshotConfig = New-AzSnapshotConfig `
			-SourceUri $newAzDisk.Id `
			-OsType Windows `
			-CreateOption Copy `
			-Location $newAzVM.location

		## Take the snapshot
		Write-Output "Creating Snapshot..."
		$snapShot = New-AzSnapshot `
			-Snapshot $snapshotConfig `
			-SnapshotName $snapshotName `
			-ResourceGroupName $varAvdImageRscGroup

		Tag-Resource -ResourceName $snapshotName -ResourceGroup $varAvdImageRscGroup -Tags $jobTags

		## Create managed disk from snapshot
		Write-Output "Creating OS Disk from Snapshot..."
		$osDisk = New-AzDisk -DiskName "$($newVMName)_OSDisk" -Disk `
		(New-AzDiskConfig  -Location $newAzVM.location -CreateOption Copy `
				-SourceResourceId $snapShot.Id) `
			-ResourceGroupName $varAvdImageRscGroup

		Write-Output "Tagging temporary resource..."
		Tag-Resource -ResourceName $osDiskName -ResourceGroup $varAvdImageRscGroup -Tags $jobTempTags

		## Determine new VM Size analyzing performance counters
		## Check if selected Size is available in currently selected location
		Write-Output "Creating Azure VM..."

		## Determine next available VM Name
		$azVMFullName = $newVMName ## ToDo: Determine next available name automatically

		## Determine next available NIC Index and final NIC Name
		$azVMNicNamePrefix = "$azVMNicPrefix-$azVMFullName"
		$azVMNicIndexNr = "001" ## ToDo - Determine Index automatically
		$azVMNicFullName = "$azVMNicNamePrefix-$azVMNicIndexNr"

		## Get Networking resources from Service Tags
		Write-Output "Getting Network information..."

		$azvNets = Get-AzResource -ResourceType Microsoft.Network/virtualNetworks

		$tagName = "AVD_ImageBuild_Resource"
		$tagValue = "True"

		Foreach ($vNet in $azvNets)
		{
			$tags = Get-AzTag -ResourceId $vNet.ResourceId

			if(($tags.Properties.TagsProperty."$tagName" -eq "$tagValue") -and ($vNet.Location -eq $newAzVM.location))
			{
				$azVMvNetRsc = $vNet
			}
		}
		if(!$azVMvNetRsc)
		{
			throw "Virtual Network Resource not found. Pleas check if tag $tagName with value $tagValue is set on the vNet Resource within the same Master VM Location."
		}
		#$azVMvNetRsc = Get-AzResource -ResourceType Microsoft.Network/virtualNetworks | Where-Object { <#($_.Tags."AVD_ImageBuild_Resource" -eq "True") -and#> ($_.Location -eq $newAzVM.location) }
		$azVMvNet = Get-AzVirtualNetwork -Name $azVMvNetRsc.Name -ResourceGroupName $azVMvNetRsc.resourceGroupName
		$azVMsNet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $azVMvNet | Where-Object { $_.Name -eq $varAvdMasterVMSubnet}

		## Create Azure Network Interface to attach
		$azVMNIC = New-AzNetworkInterface -Name $azVMNicFullName -ResourceGroupName $varAvdImageRscGroup -Location $newAzVM.location -Subnet $azVMsNet

		Tag-Resource -ResourceName $azVMNIC.Name -ResourceGroup $varAvdImageRscGroup -Tags $jobTempTags
#-------------------------------------------
		## Set OS Disk parameters
		$osDiskName = "$($azVMFullName)_OSDisk"

		$VirtualMachine = New-AzVMConfig -VMName $azVMFullName -VMSize $wvdVMSize
		$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azVMNIC.Id
		$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

		$newAzVMGeneration = Get-AzVM -Name $varAvdMasterVMName -ResourceGroupName $varAvdMasterRscGroup -Status | Select-Object -ExpandProperty HyperVGeneration

		if($newAzVMGeneration -eq "V2")
		{
			$varAvdMasterVMGen = "g2"
			if($newAzVM.SecurityProfile)
			{
				Write-Output "Detected Security Profile within source VM, setting Security Profile information for temporary VM."
				#$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "15.10" -Version "latest"
				$VirtualMachine= Set-AzVMSecurityProfile -SecurityType "TrustedLaunch" -VM $VirtualMachine
				$VirtualMachine= Set-AzVmUefi -VM $VirtualMachine -EnableVtpm $true -EnableSecureBoot $true

				$varAvdMasterVMTrustedLaunch = "tl"
			}
			else
			{
				$varAvdMasterVMTrustedLaunch = "notl"
			}
		}
		else
		{
			$varAvdMasterVMGen = "g1"
			$varAvdMasterVMTrustedLaunch = "notl"
		}

		$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $osDisk.Id -CreateOption Attach -StorageAccountType StandardSSD_LRS -DiskSizeInGB $snapShot.DiskSizeGB -Windows

		New-AzVM -ResourceGroupName $varAvdImageRscGroup -Location $newAzVM.location -VM $VirtualMachine -Verbose
#----------------------------------------------------
		## Build VM Image Name according to existing information - added A. Maiorano - 16.08.2022
		$varAvdIMGName = "img-avd-$($varAvdMasterVMGen)-$($varAvdMasterVMTrustedLaunch)-eus2-$($varAvdMasterVMWorkload)-$($varAvdMasterVMHostpoolType)"
		$varAvdCustomerName = "LEWA"
		$varAvdACGImageOffer = "$($varAvdMasterVMWorkload)-$($varAvdMasterVMHostpoolType)"
		$varAvdACGImageSKU = "$($varAvdMasterVMGen)-$($varAvdMasterVMTrustedLaunch)"


		$azVMObj = Get-AzResource -ResourceType "Microsoft.Compute/VirtualMachines" -Name $azVMFullName -ResourceGroupName $varAvdImageRscGroup

		Tag-Resource -ResourceName $azVMObj.Name -ResourceGroup $varAvdImageRscGroup -Tags $jobTempTags

		Write-Output "--------------------- Clone Virtual Machine - END ------------------------"
		Write-Output " "

		Write-Output " "
		Write-Output "--------------------- Post-Deployment Tasks - START ------------------------"

		write-output "Starting sysprep on temporary VM..."

		## Setup Azure VM Extension for sysprep
		$protectedSettings = @{"commandToExecute" = "C:\Windows\System32\Sysprep\sysprep.exe /quiet /generalize /oobe /shutdown /mode:vm" }

		Set-AzVMExtension -ResourceGroupName $varAvdImageRscGroup `
			-Location $azVMObj.Location `
			-VMName $azVMObj.Name `
			-Name "executeSysprep" `
			-Publisher "Microsoft.Compute" `
			-ExtensionType "CustomScriptExtension" `
			-TypeHandlerVersion "1.10" `
			-ProtectedSettings $protectedSettings `
			-NoWait #added cko
		## Waiting for sysprep to complete

		write-output "Waiting for Sysprep to complete after CSE provisioning..."

		$lastProvisioningState = ""
		$timeBtwChecks = 10 ## in seconds
		$provisioningState = (Get-AzVM -resourcegroupname $varAvdImageRscGroup -name $azVMFullName -Status).Statuses[1].Code
		$condition = (($provisioningState -eq "PowerState/stopped") -or ($provisioningState -eq "PowerState/deallocated"))
		while (!$condition) {
			if ($lastProvisioningState -ne $provisioningState) {
				write-output $azVMFullName "under" $varAvdImageRscGroup "is" $provisioningState "(waiting for state change)"
			}
			$lastProvisioningState = $provisioningState

			write-output "Waiting $timeBtwChecks Seconds to check again provisioning state..."
			sleep -Seconds $timeBtwChecks

			$provisioningState = (Get-AzVM -resourcegroupname $varAvdImageRscGroup -name $azVMFullName -Status).Statuses[1].Code
			$condition = (($provisioningState -eq "PowerState/stopped") -or ($provisioningState -eq "PowerState/deallocated"))
		}

		## Deallocate VM to generalize if the vm is only stopped
		if ($lastProvisioningState -eq "PowerState/stopped") {
			Stop-AzVM -ResourceGroupName $varAvdImageRscGroup -Name $azVMFullName -Force
		}

		Set-AzVm -ResourceGroupName $varAvdImageRscGroup -Name $azVMFullName -Generalized

		## Shared Image Gallery - Create image definition if not exists
		Write-Output "Create Image Gallery Definition if not exists..."
		$azSIGImage = Get-AzGalleryImageDefinition -GalleryName $varAvdACGName -Name $varAvdIMGName -ResourceGroupName $varAvdImageRscGroup -ErrorAction SilentlyContinue

		if(!$azSIGImage)
		{
			Write-Output "Image Gallery Definition does not exist. Creating..."
			if($varAvdMasterVMTrustedLaunch -eq "notl")
			{
				$azSIGImage = New-AzGalleryImageDefinition `
					-GalleryName $varAvdACGName `
					-ResourceGroupName $varAvdImageRscGroup  `
					-Location $newAzVM.location `
					-Name $varAvdIMGName `
					-OsState generalized `
					-OsType Windows `
					-Publisher $varAvdCustomerName `
					-Offer $varAvdACGImageOffer `
					-Sku $varAvdACGImageSKU `
					-HyperVGeneration $newAzVMGeneration
			}
			else
			{
				$varAvdImageFeatureSecurityType = @{Name='SecurityType';Value='TrustedLaunch'}
				$varAvdImageFeatures = @($varAvdImageFeatureSecurityType)

				$azSIGImage = New-AzGalleryImageDefinition `
					-GalleryName $varAvdACGName `
					-ResourceGroupName $varAvdImageRscGroup  `
					-Location $newAzVM.location `
					-Name $varAvdIMGName `
					-OsState generalized `
					-OsType Windows `
					-Publisher $varAvdCustomerName `
					-Offer $varAvdACGImageOffer `
					-Sku $varAvdACGImageSKU `
					-HyperVGeneration $newAzVMGeneration `
					-Feature $varAvdImageFeatures
			}

		}
		else
		{
			Write-Output "Image Gallery Definition already exists. Continue..."
		}

		Write-Output "--------------------- Post-Deployment Tasks - END ------------------------"
		Write-Output " "

		Write-Output " "
		Write-Output "--------------------- Create Image Version - START ------------------------"

		$newAzVM = Get-AzVM -Name $azVMFullName -ResourceGroupName $varAvdImageRscGroup

		write-output "Creating new image from temporary VM..."

		<## Create managed image for SIG publishing
		$azVMImageName = "image-$(Get-Date -Format "dd-MM-yyyy-HH-mm")"
		$wvdSrcImageCfg = New-AzImageConfig -Location $newAzVM.Location -SourceVirtualMachineId $newAzVM.Id
		$wvdSrcImage = New-AzImage -Image $wvdSrcImageCfg -ImageName $azVMImageName -ResourceGroupName $varAvdImageRscGroup
		$wvdSrcImageId = $wvdSrcImage.Id

		Tag-Resource -ResourceName $wvdSrcImage.Name -ResourceGroup $varAvdImageRscGroup -Tags $jobTempTags

		write-output "Successfully created image from VM."
		#>
		## Get next available image version
		$currentSIGVersions = Get-AzGalleryImageVersion -ResourceGroupName $varAvdImageRscGroup -GalleryName $varAvdACGName -GalleryImageDefinitionName $varAvdIMGName | Sort-Object { $_."PublishedDate" }

		if ($currentSIGVersions -eq $null) {
			$nextAvailableSIGVersion = [version]::New(0, 0, 1)
		}
		else {
			$latestIMGVersion = [version]$currentSIGVersions[-1].Name
			switch ($latestIMGVersion) {
				{ $_.Build -eq 9 } {
					$nextAvailableSIGVersion = [version]::New($_.Major, $_.Minor + 1, 0)
				}
				{ $_.Minor -eq 9 } {
					$nextAvailableSIGVersion = [version]::New($_.Major + 1, 0, 0)
				}
				default {
					$nextAvailableSIGVersion = [version]::New($_.Major, $_.Minor, $_.Build + 1)
				}
			}
		}

		## Set AVD version name
		$wvdVersionName = $nextAvailableSIGVersion.ToString()

		write-output "------------------------"
		write-output "-- New Image Info --"
		write-output "Image Gallery:    $varAvdACGName"
		write-output "Image Name:       $varAvdIMGName"
		write-output "Image Version:    $wvdVersionName"
		write-output "------------------------"
		write-output "Starting job to publish image to Azure compute galleries (formerly shared image gallery)"


		## Image replication start time
		write-output "------------------------"
		$imgReplStartTime = (Get-Date)
		write-output "Start Time: $imgReplStartTime"

		## Define target regions for image replication
		$currentRegion = @{Name='East US 2';ReplicaCount=1}
		#$currentRegion = @{Name='Germany West Central';ReplicaCount=1}
		#$currentRegion2 = @{Name='Germany West Central';ReplicaCount=1}
		$targetRegions = @($currentRegion<#,$currentRegion2#>)

		## Publish Image to shared image gallery
		try
		{
			$imgJob = $wvdImageVersion = New-AzGalleryImageVersion -ResourceGroupName $varAvdImageRscGroup `
				-GalleryName $varAvdACGName `
				-GalleryImageDefinitionName $varAvdIMGName `
				-Name $wvdVersionName `
				-Location $newAzVM.location `
				-SourceImageId $newAzVM.Id `
				-ReplicaCount 1 `
				-TargetRegion $targetRegions `
				-asJob

			write-output "Checking if Image version is completed..."

			while ($imgJob.State -eq "Running") {
				$secondsToWait = 60
				write-output "Image version replication running... Waiting $secondsToWait seconds..."
				Start-Sleep -Seconds $secondsToWait
			}
			$imgReplEndTime = (Get-Date)
			write-output "End Time: $imgReplEndTime"
			$imgReplDuration = NEW-TIMESPAN –Start $imgReplStartTime –End $imgReplEndTime
			write-output "Replication duration: $imgReplDuration"
			write-output "------------------------"
			write-output "Image was successfully created and published to Azure compute gallery (formerly shared image gallery)."
		}
		catch
		{
			write-output "------------------------"
			write-output "Image failed to create and publish to Azure compute gallery (formerly shared image gallery)."
		}
		write-output "------------------------"

		Write-Output "Disable capturing on Master VM for next image capture. -TBD-"
		Tag-Resource -ResourceName $varAvdMasterVMName -ResourceGroup $varAvdMasterRscGroup -Tags $jobCompleteTags

		Write-Output "Unattach Disk from temporary VM for Clean Up -TBD-"


		Write-Output "--------------------- Create Image Version - END ------------------------"
		Write-Output " "
	}
}

Write-Output " "
Write-Output "--------------------- Resource Clean Up - START ------------------------"

## Resource clean up
write-output "Starting cleanup tasks for temporary resources..."

$tempResources = Get-AzResource | Where-Object { ($_.Tags.WVDTemp -eq "$true") -and ($_.Tags.WVDJob -eq "$jobTaskName") }

while ($tempResources.Count -gt 0) {
    ## Removing every resource created for temporary tasks
    Foreach ($tempRsc in $tempResources) {
        write-output "------------------------"
        Write-Output "Removing azure resource $($tempRsc.Name) in $($tempRsc.ResourceGroupName)..."
		try
		{
			Remove-AzResource -ResourceId $tempRsc.Id -Force
        	Write-Output "Successfully removed azure resource $($tempRsc.Name)."
		}
		catch
		{
			Write-Output "Failed to remove azure resource $($tempRsc.Name)."
		}
        write-output "------------------------"
    }
    ## Wait 30 Seconds for remove actions to complete
    Start-Sleep -Seconds 30

    ## Get remaining temporary resources
    $tempResources = Get-AzResource | Where-Object { ($_.Tags.WVDTemp -eq "$true") -and ($_.Tags.WVDJob -eq "$jobTaskName") }
}

Write-Output "--------------------- Resource Clean Up - END ------------------------"
Write-Output " "
