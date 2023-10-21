/*
@author: cs2099713
@date: 2023-03-22
*/

param locationCode string
param environmentType string
param siteCode string
param appCode string

resource parentStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'stfslp${locationCode}${substring(uniqueString(locationCode, environmentType), 0, 5)}'
}

resource parentStorageAccountFileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  name: 'default'
  parent: parentStorageAccount
}

resource fileshare_siteCode_appCode_regionCode_environmentType 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'fslp-${siteCode}-${appCode}-${locationCode}-${environmentType}'
  parent: parentStorageAccountFileServices
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 102400
    enabledProtocols: 'SMB'
  }
}

output parentStorageAccountName string = parentStorageAccount.name
output parentStorageAccountID string = parentStorageAccount.id
output fileshareName string = fileshare_siteCode_appCode_regionCode_environmentType.name
output fileshareID string = fileshare_siteCode_appCode_regionCode_environmentType.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
