/*
@author: cs2099713
@date: 2023-03-22
*/
targetScope = 'subscription'
param environmentType string
param location string
param locationCode string
param siteCode string
param appCode string

param snetHostsPrefix string
param maxSessions int
param timeZone string

param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

//just here to allow usage of cluster resource templates
@secure()
param localAdminAccount string
@secure()
param localAdminPassword string

/*
      Deploy resource groups for cluster resources
----------------------------------------------------------------------------------------
*/
module rg_avd_cluster_core '../clusterResources/rg-cluster-core/deploy-rg-avd-CLUSTER-core.bicep' = {
  name: 'deploy_rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
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
module rg_avd_cluster_hosts '../clusterResources/rg-cluster-hosts/deploy-rg-avd-CLUSTER-hosts.bicep' = {
  name: 'deploy_rg-avd-${siteCode}-${appCode}-hosts-${locationCode}-${environmentType}'
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
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
//    Deploy cluster nsg
*/
module nsg_avd_cluster '../clusterResources/rg-shared-network/deploy-nsg-CLUSTER.bicep' = {
  name: 'deploy_nsg-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
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
//    Deploy cluster subnet
module snet_avd_cluster_hosts '../clusterResources/rg-shared-network/deploy-subnet-hosts-CLUSTER.bicep' = {
  name: 'deploy_snet-avd-${siteCode}-${appCode}-hosts-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-network-${locationCode}-${environmentType}')
  params: {
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
    snetHostsPrefix: snetHostsPrefix
  }
  dependsOn: [
    nsg_avd_cluster
  ]
}
/*
>Deploy resources for cluster core
----------------------------------------------------------------------------------------
//    Deploy hostpool
*/
module vdpool_avd_cluster '../clusterResources/rg-cluster-core/deploy-hostpool-CLUSTER.bicep' = {
  name: 'deploy_vdpool-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
    maxSessions: maxSessions
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
    rg_avd_cluster_core
  ]
}
//    Deploy app group
module vdag_avd_cluster '../clusterResources/rg-cluster-core/deploy-applicationGroup-CLUSTER.bicep' = {
  name: 'deploy_vdag-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
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
    vdpool_avd_cluster
  ]
}
//    Deploy scaling plan
module sp_avd_cluster '../clusterResources/rg-cluster-core/deploy-scalingPlan-CLUSTER.bicep' = {
  name: 'deploy_sp-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
    timeZone: timeZone
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
    vdpool_avd_cluster
  ]
}
//    Deploy workspace
module vdws_avd_cluster '../clusterResources/rg-cluster-core/deploy-workspace-CLUSTER.bicep' = {
  name: 'deploy_vdws-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}')
  params: {
    location: location
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
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
    vdag_avd_cluster
  ]
}
/*
>Deploy resources for cluster storage
----------------------------------------------------------------------------------------
//    Deploy fileshare
*/
module fslp_avd_cluster '../clusterResources/rg-shared-storage/deploy-fileShare-CLUSTER.bicep' = {
  name: 'deploy_fslp-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  scope: resourceGroup('rg-avd-shared-storage-${locationCode}-${environmentType}')
  params: {
    locationCode: locationCode
    environmentType: environmentType
    siteCode: siteCode
    appCode: appCode
  }
}
/*
>Output
----------------------------------------------------------------------------------------
*/
output tenantId string = rg_avd_cluster_core.outputs.tentantID
output tenantName string = rg_avd_cluster_core.outputs.tentantName

output subscription_ID string = rg_avd_cluster_core.outputs.subscriptionScopeID
output subscription_Name string = rg_avd_cluster_core.outputs.subscriptionScopeName

output rg_avd_cluster_core_Id string = rg_avd_cluster_core.outputs.resourceGroupID
output rg_avd_cluster_core_Name string = rg_avd_cluster_core.outputs.resourceGroupName

output rg_avd_cluster_hosts_Id string = rg_avd_cluster_hosts.outputs.resourceGroupID
output rg_avd_cluster_hosts_Name string = rg_avd_cluster_hosts.outputs.resourceGroupName

//----------------------------------------------------------------------
output nsg_avd_cluster_Id string = nsg_avd_cluster.outputs.nsgID
output nsg_avd_cluster_Name string = nsg_avd_cluster.outputs.nsgName
//----------------------------------------------------------------------
output snet_avd_cluster_hosts_Id string = snet_avd_cluster_hosts.outputs.snetHostsID
output snet_avd_cluster_hosts_Name string = snet_avd_cluster_hosts.outputs.snetHostsName
output snet_avd_cluster_hosts_AddressPrefix string = snet_avd_cluster_hosts.outputs.snetHostsPrefix
//----------------------------------------------------------------------
output vdpool_avd_cluster_Id string = vdpool_avd_cluster.outputs.hostpoolID
output vdpool_avd_cluster_Name string = vdpool_avd_cluster.outputs.hostpoolName
//----------------------------------------------------------------------
output vdag_avd_cluster_Id string = vdag_avd_cluster.outputs.applicationGroupID
output vdag_avd_cluster_Name string = vdag_avd_cluster.outputs.applicationGroupName
//----------------------------------------------------------------------
output sp_avd_cluster_Id string = sp_avd_cluster.outputs.scalingPlanID
output sp_avd_cluster_Name string = sp_avd_cluster.outputs.scalingPlanName
//----------------------------------------------------------------------
output vdws_avd_cluster_Id string = vdws_avd_cluster.outputs.workspaceID
output vdws_avd_cluster_Name string = vdws_avd_cluster.outputs.workspaceName
//----------------------------------------------------------------------
output fslp_avd_cluster_Id string = fslp_avd_cluster.outputs.fileshareID
output fslp_avd_cluster_Name string = fslp_avd_cluster.outputs.fileshareName
output fslp_avd_cluster_parentStorageAccountID string = fslp_avd_cluster.outputs.parentStorageAccountID
output fslp_avd_cluster_parentStorageAccountName string = fslp_avd_cluster.outputs.parentStorageAccountName
output fslp_avd_cluster_resourceGroupID string = fslp_avd_cluster.outputs.resourceGroupID
output fslp_avd_cluster_resourceGroupName string = fslp_avd_cluster.outputs.resourceGroupName
//----------------------------------------------------------------------
