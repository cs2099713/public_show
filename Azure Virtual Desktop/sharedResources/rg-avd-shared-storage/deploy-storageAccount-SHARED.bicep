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

resource st_fslp_siteCode4_appCode5 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'stfslp${locationCode}${substring(uniqueString(locationCode, environmentType), 0, 5)}'
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
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_0'
    largeFileSharesState: 'Enabled'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'
  }
}
output stName string = st_fslp_siteCode4_appCode5.name
output stID string = st_fslp_siteCode4_appCode5.id
output resourceGroupName_st string = resourceGroup().name
output resourceGroupID_st string = resourceGroup().id
