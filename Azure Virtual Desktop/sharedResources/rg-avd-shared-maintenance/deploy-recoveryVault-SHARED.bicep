/*
@author: cs2099713
@date: 2023-03-20
*/

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
resource rsv_avd_shared_regionCode_environmentType 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: 'rsv-avd-shared-${locationCode}-${environmentType}'
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
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

output rsvName string = rsv_avd_shared_regionCode_environmentType.name
output rsvID string = rsv_avd_shared_regionCode_environmentType.id
output resourceGroupName_rsv string = resourceGroup().name
output resourceGroupID_rsv string = resourceGroup().id
