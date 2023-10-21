/*
@author: cs2099713
@date: 2023-03-20
*/

param locationCode string
param environmentType string

param vnetName_Local string
param vnetSubID_Local string
param vnetRG_Local string
param vnetSub_Local string

param vnetName_Remote string
param vnetSubID_Remote string
param vnetRG_Remote string
param vnetSub_Remote string

resource local_vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName_Local
}

resource remote_vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName_Remote
  scope: resourceGroup(vnetSubID_Remote, vnetRG_Remote)
}

module virtualNetwork_Peering_LocalToRemote_Shared './deploy-virtualNetwork-singlePeering-SHARED.bicep' = {
  name: 'deploy_peer-vnet-avd-${locationCode}-${environmentType}_TO_${vnetName_Remote}'
  scope: resourceGroup(vnetRG_Local)
  params: {
    vnetName_Local: vnetName_Local

    vnetName_Remote: vnetName_Remote
    vnetSubID_Remote: vnetSubID_Remote
    vnetRG_Remote: vnetRG_Remote
  }
  dependsOn: [
    local_vnet
    remote_vnet
  ]
}

module virtualNetwork_Peering_RemoteToLocal_Shared './deploy-virtualNetwork-singlePeering-SHARED.bicep' = {
  name: 'deploy_peer-${vnetName_Remote}_TO_vnet-avd-${locationCode}-${environmentType}'
  scope: resourceGroup(vnetSubID_Remote, vnetRG_Remote)
  params: {
    vnetName_Local: vnetName_Remote

    vnetName_Remote: vnetName_Local
    vnetSubID_Remote: vnetSubID_Local
    vnetRG_Remote: vnetRG_Local
  }
  dependsOn: [
    remote_vnet
    local_vnet
  ]
}

output peerVnetLocalID string = virtualNetwork_Peering_LocalToRemote_Shared.outputs.localVnetID
output peerVnetLocalName string = virtualNetwork_Peering_LocalToRemote_Shared.outputs.localVnetName
output peerVnetLocalRG string = vnetRG_Local
output peerVnetLocalSubName string = vnetSub_Local
output peerVnetLocalSubId string = vnetSubID_Local

output peerVnetRemoteID string = virtualNetwork_Peering_LocalToRemote_Shared.outputs.remoteVnetID
output peerVnetRemoteName string = virtualNetwork_Peering_LocalToRemote_Shared.outputs.remoteVnetName
output peerVnetRemoteRG string = vnetRG_Remote
output peerVnetRemoteSubName string = vnetSub_Remote
output peerVnetRemoteSubId string = vnetSubID_Remote
