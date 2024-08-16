param managedEnvironments array
param tags object

var defaultManagedEnvironment = {
  name: ''
  tags: {}
  logAnalyticsWorkspace: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
  }
  enableAzureMonitorLogsDestination: true
  certificates: []
  daprComponents: []
  daprApplicationInsights: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
  }
  storages: []
  virtualNetwork: {
    infrastructureSubnet: {
      resourceGroup: ''
      name: ''
      subnetName: ''
    }
    internal: false
    dockerBridgeCidr: ''
    platformReservedCidr: ''
    dnsIp: ''
  }
  zoneRedundant: false
  workloadProfiles: []
  diagnosticSettings: {
    logAnalyticsWorkspace: {
      name: ''
      resourceGroup: ''
      subscriptionId: subscription().subscriptionId
      enabledLogs: []
      enabledMetrics: []
    }
    eventHub: {
      namespace: ''
      name: ''
      resourceGroup: ''
      subscriptionId: subscription().subscriptionId
      policyName: 'RootManageSharedAccessKey'
      enabledLogs: []
      enabledMetrics: []
    }
    storageAccount: {
      name: ''
      resourceGroup: ''
      subscriptionId: subscription().subscriptionId
      enabledLogs: []
      enabledMetrics: []
    }
  }
}




/*
resource logAnalyticsWorkspaces 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = [for (managedEnvironment, i) in managedEnvironments: if (!empty(union(defaultManagedEnvironment, managedEnvironment).logAnalyticsWorkspace.name)) {
  name: managedEnvironment.logAnalyticsWorkspace.name
  scope: resourceGroup(union(defaultManagedEnvironment, managedEnvironment).logAnalyticsWorkspace.subscriptionId, managedEnvironment.logAnalyticsWorkspace.resourceGroup)
}]
*/



module managedEnvironmentsRes 'managed-environment.bicep' = [for (managedEnvironment, i) in managedEnvironments: {
  name: 'managedEnvironment-${uniqueString(resourceGroup().name)}-${i}'
  params: {
    managedEnvironment: union(defaultManagedEnvironment, managedEnvironment)
    //workspaceId: !empty(union(defaultManagedEnvironment, managedEnvironment).logAnalyticsWorkspace.name) ? logAnalyticsWorkspaces[i].properties.customerId : ''
    //workspacePrimarySharedKey: !empty(union(defaultManagedEnvironment, managedEnvironment).logAnalyticsWorkspace.name) ? logAnalyticsWorkspaces[i].listKeys().primarySharedKey : ''
    tags: union(tags, union(defaultManagedEnvironment, managedEnvironment).tags)
  }
}]

output managedEnvironments array = [for (managedEnvironment, i) in managedEnvironments: managedEnvironmentsRes[i].outputs.managedEnvironment]
