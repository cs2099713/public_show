# Sign in to your Azure subscription
try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$maxremoveperrun = 2

write-output "The script will remove max $maxremoveperrun objects of each type per run."
write-output "--------------------------------------------------------------------------------------------------------------------------"

$Disks = Get-AzDisk | where {($_.DiskState -like "Unattached") -and ($_.Tags."doNotDelete" -ne "True")} | Select-Object Name, ResourceGroupName
write-output "found orphaned Disks:" $Disks

$i = 0
foreach ($Disk in $Disks)
{
    $i++
    write-output "Removing orphaned Disk $($Disk.Name)"
    Remove-AzDisk -DiskName $Disk.Name -ResourceGroupName $Disk.ResourceGroupName -Force
    if ($i -eq $maxremoveperrun) {break}
}
write-output "--------------------------------------------------------------------------------------------------------------------------"


#$Interfaces = Get-AzResource -ResourceType "Microsoft.Network/networkInterfaces" | Where-Object {$_.Tags."doNotDelete" -ne "True"}	#funktioniert
$Interfaces = Get-AzNetworkInterface | Where-Object { ($_.VirtualMachine -eq $null) -and (($_.PrivateEndpointText -eq $null) -Or ($_.PrivateEndpointText -eq 'null')) -and ($_.Tag."doNotDelete" -ne "True")} | Select-Object Name, ResourceGroupName
write-output "found orphaned Interfaces:" $Interfaces

$i = 0
foreach ($Interface in $Interfaces)
{
    $i++
    write-output "Removing orphaned Interface $($Interface.Name)"
    Remove-AzNetworkInterface -Name $Interface.Name -ResourceGroupName $Interface.ResourceGroupName -Force
    if ($i -eq $maxremoveperrun) {break}
}
write-output "--------------------------------------------------------------------------------------------------------------------------"


$availabilitySets = Get-AzAvailabilitySet | Where-Object {($_.VirtualMachinesReferences.Count -eq 0) -and ($_.Tags."doNotDelete" -ne "True")} | Select-Object Name, ResourceGroupName
write-output "found orphaned Availability Sets:" $availabilitySets

$i = 0
foreach ($availabilitySet in $availabilitySets)
{
    $i++
    write-output "Removing orphaned Availability Set $($availabilitySet.Name)"
    Remove-AzAvailabilitySet -Name $availabilitySet.Name -ResourceGroupName $availabilitySet.ResourceGroupName -Force
    if ($i -eq $maxremoveperrun) {break}
}
write-output "--------------------------------------------------------------------------------------------------------------------------"

write-output "Script finished."