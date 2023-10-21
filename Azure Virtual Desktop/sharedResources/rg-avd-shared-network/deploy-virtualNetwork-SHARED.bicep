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

param vnetAddressPrefix string
param primaryDNS string
param secondaryDNS string

resource vnet_avd_shared_network_regionCode_environmentType 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-avd-shared-network-${locationCode}-${environmentType}'
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
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        primaryDNS
        secondaryDNS
      ]
    }
  }
}

output vnetName string = vnet_avd_shared_network_regionCode_environmentType.name
output vnetID string = vnet_avd_shared_network_regionCode_environmentType.id
output vnetSubId string = subscription().subscriptionId
output vnetRG string = resourceGroup().name
output vnetSubName string = subscription().displayName
output vnetAddressPrefix string = vnetAddressPrefix
output vnetPrimaryDNS string = primaryDNS
output vnetSecondaryDNS string = secondaryDNS
