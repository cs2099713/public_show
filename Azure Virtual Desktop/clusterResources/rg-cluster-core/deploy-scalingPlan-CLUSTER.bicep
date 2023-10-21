/*
@author: cs2099713
@date: 2023-03-22
*/

param location string
param locationCode string
param environmentType string
param siteCode string
param appCode string
param timeZone string
param tagsBilling string
param tagsBillingService string
param tagsBillingSite string
param deploymentDate string
param deploymentSite string
param deploymentApp string
param deploymentRegion string
param deploymentBy string

resource armHostpool 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' existing = {
  name: 'vdpool-avd-${siteCode}-${appCode}-${locationCode}-${environmentType}'
}

resource sp_siteCode_appCode_locationCode_environmentType 'Microsoft.DesktopVirtualization/scalingplans@2022-10-14-preview' = {
  name: 'sp-${siteCode}-${appCode}-${locationCode}-${environmentType}'
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
    timeZone: timeZone
    hostPoolType: 'Pooled'
    exclusionTag: 'AVD_AutoScale_Exclude'
    schedules: [
      {
        rampUpStartTime: {
          hour: 8
          minute: 0
        }
        peakStartTime: {
          hour: 10
          minute: 0
        }
        rampDownStartTime: {
          hour: 15
          minute: 0
        }
        offPeakStartTime: {
          hour: 17
          minute: 0
        }
        name: 'schedule-weekend-01'
        daysOfWeek: [
          'Saturday'
          'Sunday'
        ]
        rampUpLoadBalancingAlgorithm: 'DepthFirst'
        rampUpMinimumHostsPct: 0
        rampUpCapacityThresholdPct: 90
        peakLoadBalancingAlgorithm: 'DepthFirst'
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 0
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: false
        rampDownWaitTimeMinutes: 30
        rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
        rampDownStopHostsWhen: 'ZeroSessions'
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
      }
      {
        rampUpStartTime: {
          hour: 7
          minute: 0
        }
        peakStartTime: {
          hour: 9
          minute: 0
        }
        rampDownStartTime: {
          hour: 17
          minute: 0
        }
        offPeakStartTime: {
          hour: 19
          minute: 0
        }
        name: 'schedule-weekdays-01'
        daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        rampUpLoadBalancingAlgorithm: 'DepthFirst'
        rampUpMinimumHostsPct: 0
        rampUpCapacityThresholdPct: 75
        peakLoadBalancingAlgorithm: 'DepthFirst'
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 0
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: false
        rampDownWaitTimeMinutes: 30
        rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
        rampDownStopHostsWhen: 'ZeroSessions'
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
      }
    ]
    hostPoolReferences: [
      {
        hostPoolArmPath: armHostpool.id
        scalingPlanEnabled: true
      }
    ]
  }
}

output scalingPlanName string = sp_siteCode_appCode_locationCode_environmentType.name
output scalingPlanID string = sp_siteCode_appCode_locationCode_environmentType.id
output hostpoolName string = armHostpool.name
output hostpoolID string = armHostpool.id
output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output subscriptionScopeName string = subscription().displayName
output subscriptionScopeID string = subscription().subscriptionId
output tentantName string = tenant().displayName
output tentantID string = tenant().tenantId
