/*
@author: cs2099713
@date: 2023-03-20
*/

param location string
param locationCode string
param environmentType string
param vnetAddressPrefix string
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

resource nsg_avd_endpoints_regionCode_environmentType 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-avd-endpoints-${locationCode}-${environmentType}'
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
resource nsg_avd_endpoints_AllowAvdVnetSMB445Inbound 'Microsoft.Network/networkSecurityGroups/securityRules@2022-07-01' = {
  name: 'AllowAvdVnetSMB445Inbound'
  parent: nsg_avd_endpoints_regionCode_environmentType
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '445'
    sourceAddressPrefix: vnetAddressPrefix
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

output nsgName string = nsg_avd_endpoints_regionCode_environmentType.name
output nsgID string = nsg_avd_endpoints_regionCode_environmentType.id
output resourceGroupName_nsg string = resourceGroup().name
output resourceGroupID_nsg string = resourceGroup().id
