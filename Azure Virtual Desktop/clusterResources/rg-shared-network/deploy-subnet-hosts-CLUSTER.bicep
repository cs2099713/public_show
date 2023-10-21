/*
@author: cs2099713
@date: 2023-03-22
*/

param locationCode string
param environmentType string
param siteCode string
param appCode string
param snetHostsPrefix string

resource parentVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-avd-shared-network-${locationCode}-${environmentType}'
}
resource assignRouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = {
  name: 'rt-avd-shared-network-${locationCode}-${environmentType}'
}
resource assignNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' existing = {
  name: 'nsg-avd-${siteCode}-${appCode}-hosts-${locationCode}-${environmentType}'
}
resource snet_avd_siteCode_appCode_hosts_regionCode_environmentType 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: 'snet-avd-${siteCode}-${appCode}-hosts-${locationCode}-${environmentType}'
  parent: parentVnet
  properties: {
    addressPrefix: snetHostsPrefix
    routeTable: {
      id: assignRouteTable.id
    }
    networkSecurityGroup: {
      id: assignNSG.id
    }
  }
}

output snetHostsName string = snet_avd_siteCode_appCode_hosts_regionCode_environmentType.name
output snetHostsID string = snet_avd_siteCode_appCode_hosts_regionCode_environmentType.id
output snetHostsPrefix string = snetHostsPrefix
output parentVnetName string = parentVnet.name
output parentVnetid string = parentVnet.id
output assignedRtName string = assignRouteTable.name
output assignedRtId string = assignRouteTable.id
output assignedNsgName string = assignNSG.name
output assignedNsgId string = assignNSG.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
