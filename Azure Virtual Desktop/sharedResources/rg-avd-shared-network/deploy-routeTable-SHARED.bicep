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

param routeTableNextHopIPAddress string

resource rt_avd_shared_network_regionCode_environmentType 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'rt-avd-shared-network-${locationCode}-${environmentType}'
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
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-default-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }, {
        name: 'route-to-de-client-network'
        properties: {
          addressPrefix: '172.16.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: routeTableNextHopIPAddress
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }, {
        name: 'route-to-srv-network'
        properties: {
          addressPrefix: '10.100.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: routeTableNextHopIPAddress
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }, {
        name: 'route-to-mep'
        properties: {
          addressPrefix: '10.200.0.0/20'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: routeTableNextHopIPAddress
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }, {
        name: 'route-to-branch-we-networks'
        properties: {
          addressPrefix: '10.50.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: routeTableNextHopIPAddress
          hasBgpOverride: false
        }
        type: 'Microsoft.Network/routeTables/routes'
      }

    ]
  }
}

output rtName string = rt_avd_shared_network_regionCode_environmentType.name
output rtID string = rt_avd_shared_network_regionCode_environmentType.id
output resourceGroupName_rt string = resourceGroup().name
output resourceGroupID_rt string = resourceGroup().id
