/*
@author: cs2099713
@date: 2023-03-20
*/

param vnetName_Local string

param vnetName_Remote string
param vnetSubID_Remote string
param vnetRG_Remote string

resource local_vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName_Local
}

resource remote_vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName_Remote
  scope: resourceGroup(vnetSubID_Remote, vnetRG_Remote)
}

resource vnet_avd_shared_network_peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: 'peer-${vnetName_Local}_TO_${vnetName_Remote}'
  parent: local_vnet
  properties: {
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: remote_vnet.id
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: remote_vnet.properties.addressSpace.addressPrefixes
    }
  }
  dependsOn: [
    remote_vnet
  ]
}

output localVnetName string = local_vnet.name
output localVnetID string = local_vnet.id
output remoteVnetName string = remote_vnet.name
output remoteVnetID string = remote_vnet.id
