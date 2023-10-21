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

resource aa_avd_shared_regionCode_environmentType_uniqueString 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: 'aa-avd-shared-${locationCode}-${environmentType}-${uniqueString(resourceGroup().id, environmentType)}'
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
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {
      }
    }
  }
}

output aaName string = aa_avd_shared_regionCode_environmentType_uniqueString.name
output aaID string = aa_avd_shared_regionCode_environmentType_uniqueString.id
output resourceGroupName_aa string = resourceGroup().name
output resourceGroupID_aa string = resourceGroup().id
