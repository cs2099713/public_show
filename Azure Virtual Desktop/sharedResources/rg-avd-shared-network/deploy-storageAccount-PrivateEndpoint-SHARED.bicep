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
/*
resource rgsharednetwork 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-avd-shared-network-${locationCode}-${environmentType}'
  scope: subscription()
}*/
resource rgsharedstorage 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-avd-shared-storage-${locationCode}-${environmentType}'
  scope: subscription()
}
resource parentVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-avd-shared-network-${locationCode}-${environmentType}'
  //scope: resourceGroup(rgsharednetwork.name)
}
resource assignedSnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'snet-avd-endpoints-${locationCode}-${environmentType}'
  //scope: resourceGroup(rgsharednetwork.name)
}

resource linkedStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'stfslp${locationCode}${substring(uniqueString(locationCode, environmentType), 0, 5)}'
  scope: resourceGroup(rgsharedstorage.name)
}

resource pep_st_fslp_siteCode4_appCode5 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: 'pep-${linkedStorageAccount.name}-${uniqueString(locationCode, environmentType)}'
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
    privateLinkServiceConnections: [
      {
        name: 'con-${linkedStorageAccount.name}-PrivateLink'
        properties: {
          privateLinkServiceId: linkedStorageAccount.id
          groupIds: [
            'file'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: '${parentVnet.id}/subnets/${assignedSnet.name}'
    }
  }
}
var privateDnsZoneNameStorage = 'privatelink.file.${environment().suffixes.storage}'
resource privateDnsZoneStorage 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
  properties: {}
}

resource privateDnsZoneLinkStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneStorage
  name: '${privateDnsZoneNameStorage}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: parentVnet.id
    }
  }
}

resource pvtEndpointStoraeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-09-01' = {
  parent: pep_st_fslp_siteCode4_appCode5
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameStorage
        properties: {
          privateDnsZoneId: privateDnsZoneStorage.id
        }
      }
    ]
  }
}

output storageAccountPrivateEndpointName string = pep_st_fslp_siteCode4_appCode5.name
output storageAccountPrivateEndpointID string = pep_st_fslp_siteCode4_appCode5.id
output resourceGroupName_pep string = resourceGroup().name
output resourceGroupID_pep string = resourceGroup().id
