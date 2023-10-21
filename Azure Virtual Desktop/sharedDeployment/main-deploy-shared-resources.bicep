/*
@author: cs2099713
@date: 2023-03-21
*/
targetScope = 'subscription'

param location string
param locationCode string
param environmentType string
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

param vnetAddressPrefix string
param primaryDNS string
param secondaryDNS string

param vnetName_OS string
param vnetSubID_OS string
param vnetRG_OS string
param vnetSub_OS string

param vnetName_CORE string
param vnetSubID_CORE string
param vnetRG_CORE string
param vnetSub_CORE string

param routeTableNextHopIPAddress string

param snetEndpointsPrefix string

/*
      Deploy resource groups for shared resources
----------------------------------------------------------------------------------------
*/
module rg_shared_network '../sharedResources/rg-avd-shared-network/deploy-rg-avd-SHARED-network.bicep' = {
  name: 'deploy_rg-avd-shared-network-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
}
module rg_shared_maintenance '../sharedResources/rg-avd-shared-maintenance/deploy-rg-avd-SHARED-maintenance.bicep' = {
  name: 'deploy_rg-avd-shared-maintenance-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
}
module rg_shared_storage '../sharedResources/rg-avd-shared-storage/deploy-rg-avd-SHARED-storage.bicep' = {
  name: 'deploy_rg-avd-shared-storage-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
}
module rg_shared_image '../sharedResources/rg-avd-shared-image/deploy-rg-avd-SHARED-image.bicep' = {
  name: 'deploy_rg-avd-shared-image-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
}
module rg_shared_master '../sharedResources/rg-avd-shared-master/deploy-rg-avd-SHARED-master.bicep' = {
  name: 'deploy_rg-avd-shared-master-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
}

/*
>Deploy resources for shared network
----------------------------------------------------------------------------------------
//    Deploy vnet
*/
module shared_network '../sharedResources/rg-avd-shared-network/deploy-virtualNetwork-SHARED.bicep' = {
  name: 'deploy_vnet-avd-shared-network-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy

    vnetAddressPrefix: vnetAddressPrefix
    primaryDNS: primaryDNS
    secondaryDNS: secondaryDNS
  }
  dependsOn: [
    rg_shared_network
  ]
}
//    Deploy peering
module shared_network_Peering_Core_Shared '../sharedResources/rg-avd-shared-network/deploy-virtualNetwork-bidirectionalPeering-SHARED.bicep' = {
  name: 'deploy_peer-vnet-avd-${locationCode}-${environmentType}-WITH-${vnetName_CORE}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    locationCode: locationCode
    environmentType: environmentType

    vnetName_Local: shared_network.outputs.vnetName
    vnetSubID_Local: shared_network.outputs.vnetSubId
    vnetRG_Local: shared_network.outputs.vnetRG
    vnetSub_Local: shared_network.outputs.vnetSubName

    vnetName_Remote: vnetName_CORE
    vnetSubID_Remote: vnetSubID_CORE
    vnetRG_Remote: vnetRG_CORE
    vnetSub_Remote: vnetSub_CORE
  }
  dependsOn: [
    shared_network
  ]
}
module shared_network_Peering_OpenSystems_Shared '../sharedResources/rg-avd-shared-network/deploy-virtualNetwork-bidirectionalPeering-SHARED.bicep' = {
  name: 'deploy_peer-vnet-avd-${locationCode}-${environmentType}-WITH-${vnetName_OS}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    locationCode: locationCode
    environmentType: environmentType

    vnetName_Local: shared_network.outputs.vnetName
    vnetSubID_Local: shared_network.outputs.vnetSubId
    vnetRG_Local: shared_network.outputs.vnetRG
    vnetSub_Local: shared_network.outputs.vnetSubName

    vnetName_Remote: vnetName_OS
    vnetSubID_Remote: vnetSubID_OS
    vnetRG_Remote: vnetRG_OS
    vnetSub_Remote: vnetSub_OS
  }
  dependsOn: [
    shared_network
  ]
}
//    Deploy routetable
module routeTable_Shared '../sharedResources/rg-avd-shared-network/deploy-routeTable-SHARED.bicep' = {
  name: 'deploy_rt-avd-shared-network-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy

    routeTableNextHopIPAddress: routeTableNextHopIPAddress
  }
  dependsOn: [
    rg_shared_network
  ]
}
//    Deploy nsg for endpoints
module nsg_avd_endpoints_Shared '../sharedResources/rg-avd-shared-network/deploy-nsg-endpoints-SHARED.bicep' = {
  name: 'deploy_nsg-avd-endpoints-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    vnetAddressPrefix: vnetAddressPrefix
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    shared_network
  ]
}
//    Deploy subnet for endpoints
module snet_avd_cluster_endpoints_Shared '../sharedResources/rg-avd-shared-network/deploy-subnet-endpoints-SHARED.bicep' = {
  name: 'deploy_snet-avd-endpoints-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    locationCode: locationCode
    environmentType: environmentType

    snetEndpointsPrefix: snetEndpointsPrefix
  }
  dependsOn: [
    nsg_avd_endpoints_Shared
    routeTable_Shared
  ]
}

//    Deploy private endpoint for storage account
module pep_st_fslp_shared '../sharedResources/rg-avd-shared-network/deploy-storageAccount-PrivateEndpoint-SHARED.bicep' = {
  name: 'deploy_pep-${stName}-${uniqueString(locationCode, environmentType)}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    st_fslp_shared_region
  ]
}

/*
>Deploy resources for shared storage
----------------------------------------------------------------------------------------
//    Deploy storage account
*/
var stName = 'stfslp${locationCode}${substring(uniqueString(locationCode, environmentType), 0, 5)}'
module st_fslp_shared_region '../sharedResources/rg-avd-shared-storage/deploy-storageAccount-SHARED.bicep' = {
  name: 'deploy_${stName}'
  scope: resourceGroup('rg-avd-shared-storage-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    rg_shared_storage
    snet_avd_cluster_endpoints_Shared
  ]
}

/*
>Deploy resources for shared maintenance
----------------------------------------------------------------------------------------
//    Deploy automation account
*/
module automationAccount_Shared '../sharedResources/rg-avd-shared-maintenance/deploy-automationAccount-SHARED.bicep' = {
  name: 'deploy_aa-avd-shared-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-maintenance-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    rg_shared_maintenance
  ]
}
//    Deploy log analytics workspace
module logAnalytics_Shared '../sharedResources/rg-avd-shared-maintenance/deploy-logAnalytics-SHARED.bicep' = {
  name: 'deploy_log-avd-shared-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-maintenance-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    rg_shared_maintenance
  ]
}
//    Deploy recovery vault services
module recoveryVault_Shared '../sharedResources/rg-avd-shared-maintenance/deploy-recoveryVault-SHARED.bicep' = {
  name: 'deploy_rsv-avd-shared-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-maintenance-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    rg_shared_maintenance
  ]
}
/*
>Deploy resources for shared maintenance
----------------------------------------------------------------------------------------
//    Deploy shared compute gallery
*/
module computeGallery_shared '../sharedResources/rg-avd-shared-image/deploy-computeGallery-SHARED.bicep' = {
  name: 'deploy_gal_avd_shared_${locationCode}_${environmentType}'
  scope: resourceGroup('rg-avd-shared-image-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    tagsBilling: tagsBilling
    tagsBillingService: tagsBillingService
    tagsBillingSite: tagsBillingSite
    deploymentDate: deploymentDate
    deploymentSite: deploymentSite
    deploymentApp: deploymentApp
    deploymentRegion: deploymentRegion
    deploymentBy: deploymentBy
  }
  dependsOn: [
    rg_shared_image
  ]
}
/*
>Output
----------------------------------------------------------------------------------------
*/
output tenantId string = rg_shared_network.outputs.tentantID
output tenantName string = rg_shared_network.outputs.tentantName

output subscription_ID string = rg_shared_network.outputs.subscriptionScopeID
output subscription_Name string = rg_shared_network.outputs.subscriptionScopeName

output rg_shared_network_Id string = rg_shared_network.outputs.rgSharedNetworkId
output rg_shared_network_Name string = rg_shared_network.outputs.rgSharedNetworkName

output rg_shared_maintenance_Id string = rg_shared_maintenance.outputs.rgSharedMaintenanceId
output rg_shared_maintenance_Name string = rg_shared_maintenance.outputs.rgSharedMaintenanceName

output rg_shared_storage_Id string = rg_shared_storage.outputs.rgSharedStorageId
output rg_shared_storage_Name string = rg_shared_storage.outputs.rgSharedStorageName

output rg_shared_image_Id string = rg_shared_image.outputs.rgSharedImageId
output rg_shared_image_Name string = rg_shared_image.outputs.rgSharedImageName

output rg_shared_master_Id string = rg_shared_master.outputs.rgSharedMasterId
output rg_shared_master_Name string = rg_shared_master.outputs.rgSharedMasterName

//----------------------------------------------------------------------
output shared_network_Id string = shared_network.outputs.vnetID
output shared_network_Name string = shared_network.outputs.vnetName
output shared_network_AddressPrefix string = shared_network.outputs.vnetAddressPrefix
output shared_network_PrimaryDNS string = shared_network.outputs.vnetPrimaryDNS
output shared_network_SecondaryDNS string = shared_network.outputs.vnetSecondaryDNS
output shared_network_Peering_OpenSystems_Vnet_Id string = shared_network_Peering_OpenSystems_Shared.outputs.peerVnetRemoteID
output shared_network_Peering_OpenSystems_Vnet_Name string = shared_network_Peering_OpenSystems_Shared.outputs.peerVnetRemoteName
output shared_network_Peering_OpenSystems_Vnet_RG string = shared_network_Peering_OpenSystems_Shared.outputs.peerVnetRemoteRG
output shared_network_Peering_OpenSystems_Vnet_Subscription string = shared_network_Peering_OpenSystems_Shared.outputs.peerVnetRemoteSubName
output shared_network_Peering_Core_Vnet_Id string = shared_network_Peering_Core_Shared.outputs.peerVnetRemoteID
output shared_network_Peering_Core_Vnet_Name string = shared_network_Peering_Core_Shared.outputs.peerVnetRemoteName
output shared_network_Peering_Core_Vnet_RG string = shared_network_Peering_Core_Shared.outputs.peerVnetRemoteRG
output shared_network_Peering_Core_Vnet_Subscription string = shared_network_Peering_Core_Shared.outputs.peerVnetRemoteSubName
//----------------------------------------------------------------------
output routeTable_Shared_Id string = routeTable_Shared.outputs.rtID
output routeTable_Shared_Name string = routeTable_Shared.outputs.rtName
//----------------------------------------------------------------------
output nsg_avd_endpoints_Shared_Id string = nsg_avd_endpoints_Shared.outputs.nsgID
output nsg_avd_endpoints_Shared_Name string = nsg_avd_endpoints_Shared.outputs.nsgName
//----------------------------------------------------------------------
output snet_avd_cluster_endpoints_Shared_Id string = snet_avd_cluster_endpoints_Shared.outputs.snetEndpointsID
output snet_avd_cluster_endpoints_Shared_Name string = snet_avd_cluster_endpoints_Shared.outputs.snetEndpointsName
output snet_avd_cluster_endpoints_Shared_AddressPrefix string = snet_avd_cluster_endpoints_Shared.outputs.snetEndpointsPrefix
//----------------------------------------------------------------------
output st_fslp_shared_region_Id string = st_fslp_shared_region.outputs.stID
output st_fslp_shared_region_Name string = st_fslp_shared_region.outputs.stName
//----------------------------------------------------------------------
output pep_st_fslp_shared_Id string = pep_st_fslp_shared.outputs.storageAccountPrivateEndpointID
output pep_st_fslp_shared_Name string = pep_st_fslp_shared.outputs.storageAccountPrivateEndpointName
//----------------------------------------------------------------------
output automationAccount_Shared_Id string = automationAccount_Shared.outputs.aaID
output automationAccount_Shared_Name string = automationAccount_Shared.outputs.aaName
//----------------------------------------------------------------------
output logAnalytics_Shared_Id string = logAnalytics_Shared.outputs.logID
output logAnalytics_Shared_Name string = logAnalytics_Shared.outputs.logName
//----------------------------------------------------------------------
output recoveryVault_Shared_Id string = recoveryVault_Shared.outputs.rsvID
output recoveryVault_Shared_Name string = recoveryVault_Shared.outputs.rsvName
//----------------------------------------------------------------------
//----------------------------------------------------------------------
output computeGallery_shared_Id string = computeGallery_shared.outputs.galID
output computeGallery_shared_Name string = computeGallery_shared.outputs.galName
//----------------------------------------------------------------------
