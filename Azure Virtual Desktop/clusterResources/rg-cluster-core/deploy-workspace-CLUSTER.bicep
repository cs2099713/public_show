/*
@author: cs2099713
@date: 2023-03-22
*/

param location string
param locationCode string
param environmentType string
param siteCode string
param appCode string
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

var friendlyName = '${siteCode} - ${appCode} - Virtual Desktop'

resource refApplicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2022-10-14-preview' existing = {
  name: 'vdag-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
}

resource vdws_avd_siteCode_appCode_locationCode_environmentType 'Microsoft.DesktopVirtualization/workspaces@2022-10-14-preview' = {
  name: 'vdws-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
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
    friendlyName: friendlyName
    applicationGroupReferences: [
      refApplicationGroup.id
    ]
  }
}

output workspaceName string = vdws_avd_siteCode_appCode_locationCode_environmentType.name
output workspaceID string = vdws_avd_siteCode_appCode_locationCode_environmentType.id
output refApplicationGroupName string = refApplicationGroup.name
output refApplicationGroupID string = refApplicationGroup.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
