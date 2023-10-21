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

resource gal_avd_shared_regionCode_environmentType 'Microsoft.Compute/galleries@2022-03-03' = {
  name: 'gal_avd_shared_${locationCode}_${environmentType}'
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

output galName string = gal_avd_shared_regionCode_environmentType.name
output galID string = gal_avd_shared_regionCode_environmentType.id
output resourceGroupName_gal string = resourceGroup().name
output resourceGroupID_gal string = resourceGroup().id
