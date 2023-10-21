/*
@author: cs2099713
@date: 2023-03-22
*/

param location string
param locationCode string
param environmentType string
param siteCode string
param appCode string
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string
@secure()
param localAdminAccount string
@secure()
param localAdminPassword string
//just here to allow usage of cluster resource templates
param snetHostsPrefix string
param maxSessions int
param timeZone string

resource rgsharednetwork 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-avd-shared-network-${locationCode}-${environmentType}'
  scope: subscription()
}

resource parentVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-avd-shared-network-${locationCode}-${environmentType}'
  scope: resourceGroup(rgsharednetwork.name)
}

resource assignedSnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: 'snet-avd-${siteCode}-${appCode}-hosts-${locationCode}-${environmentType}'
  scope: resourceGroup(rgsharednetwork.name)
}
resource networkInterface 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: 'nic-${toLower('VM${siteCode}${appCode}M${substring(uniqueString(resourceGroup().id, environmentType), 0, 3)}')}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${parentVnet.id}/subnets/${assignedSnet.name}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
  }
}

resource vm_siteCode_appCode_M_uniqueString 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'VM${toUpper(siteCode)}${toUpper(appCode)}M${toUpper(substring(uniqueString(resourceGroup().id, environmentType), 0, 3))}'
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
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-22h2-avd-g2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'VM${siteCode}${appCode}M${substring(uniqueString(resourceGroup().id, environmentType), 0, 3)}'
      adminUsername: localAdminAccount
      adminPassword: localAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
  }
}

output vmMasterName string = vm_siteCode_appCode_M_uniqueString.name
output vmMasterID string = vm_siteCode_appCode_M_uniqueString.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
