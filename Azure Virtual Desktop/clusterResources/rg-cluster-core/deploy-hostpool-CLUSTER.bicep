/*
@author: cs2099713
@date: 2023-03-22
*/

param location string
param locationCode string
param environmentType string
param siteCode string
param appCode string
param maxSessions int
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

resource vdpool_avd_siteCode_appCode_locationCode_environmentType 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' = {
  name: 'vdpool-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  location: location
  tags: {
    Billing: tagsBilling
    BillingSite: tagsBillingSite
    BillingService: tagsBillingService
    'Deployment Date': deploymentDate
    'Deployment Site': deploymentSite
    'Deployment App': deploymentApp
    'Deployment Region': deploymentRegion
    'Deployed By': deploymentBy
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    hostPoolType: 'Pooled'
    customRdpProperty: 'drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;audiocapturemode:i:1;encode redirected video capture:i:1;camerastoredirect:s:*;'
    maxSessionLimit: maxSessions
    loadBalancerType: 'DepthFirst'
    validationEnvironment: false
    preferredAppGroupType: 'Desktop'
    startVMOnConnect: true
  }
}

output hostpoolName string = vdpool_avd_siteCode_appCode_locationCode_environmentType.name
output hostpoolID string = vdpool_avd_siteCode_appCode_locationCode_environmentType.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
