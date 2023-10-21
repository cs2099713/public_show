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

resource log_avd_shared_regionCode_environmentType 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-avd-shared-${locationCode}-${environmentType}'
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
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output logName string = log_avd_shared_regionCode_environmentType.name
output logID string = log_avd_shared_regionCode_environmentType.id
output resourceGroupName_log string = resourceGroup().name
output resourceGroupID_log string = resourceGroup().id
