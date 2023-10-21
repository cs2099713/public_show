/*
@author: cs2099713
@date: 2023-03-20
*/

param locationCode string
param environmentType string

param snetEndpointsPrefix string

resource parentVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-avd-shared-network-${locationCode}-${environmentType}'
}
resource assignRouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = {
  name: 'rt-avd-shared-network-${locationCode}-${environmentType}'
}
resource assignNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' existing = {
  name: 'nsg-avd-endpoints-${locationCode}-${environmentType}'
}

resource snet_avd_endpoints_regionCode_environmentType 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: 'snet-avd-endpoints-${locationCode}-${environmentType}'
  parent: parentVnet
  properties: {
    addressPrefix: snetEndpointsPrefix
    routeTable: {
      id: assignRouteTable.id
    }
    networkSecurityGroup: {
      id: assignNSG.id
    }
  }
  dependsOn: [
    assignRouteTable
    assignNSG
  ]

}

output snetEndpointsName string = snet_avd_endpoints_regionCode_environmentType.name
output snetEndpointsID string = snet_avd_endpoints_regionCode_environmentType.id
output snetEndpointsPrefix string = snetEndpointsPrefix
output parentVnetName string = parentVnet.name
output parentVnetid string = parentVnet.id
output assignedRtName string = assignRouteTable.name
output assignedRtId string = assignRouteTable.id
output assignedNsgName string = assignNSG.name
output assignedNsgId string = assignNSG.id
