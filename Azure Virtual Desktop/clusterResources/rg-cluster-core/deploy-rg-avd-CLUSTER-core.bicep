/*
@author: cs2099713
@date: 2023-03-22
*/

targetScope = 'subscription'
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

resource rg_avd_siteCode_appCode_core_regioncode_environmentType 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-avd-${siteCode}-${appCode}-core-${locationCode}-${environmentType}'
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
}

output resourceGroupName string = rg_avd_siteCode_appCode_core_regioncode_environmentType.name
output resourceGroupID string = rg_avd_siteCode_appCode_core_regioncode_environmentType.id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
