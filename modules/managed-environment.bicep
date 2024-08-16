param managedEnvironment object
//param workspaceId string
@secure()
//param workspacePrimarySharedKey string
param tags object

resource daprAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(managedEnvironment.daprApplicationInsights.name)) {
  name: managedEnvironment.daprApplicationInsights.name
  scope: resourceGroup(managedEnvironment.daprApplicationInsights.subscriptionId, managedEnvironment.daprApplicationInsights.resourceGroup)
}

resource infrastructureVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = if (!empty(managedEnvironment.virtualNetwork.infrastructureSubnet.name)) {
  name: managedEnvironment.virtualNetwork.infrastructureSubnet.name
  scope: resourceGroup(managedEnvironment.virtualNetwork.infrastructureSubnet.resourceGroup)
}

resource infrastructureSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = if (!empty(managedEnvironment.virtualNetwork.infrastructureSubnet.name)) {
  name: managedEnvironment.virtualNetwork.infrastructureSubnet.subnetName
  parent: infrastructureVnet
}

// this was added because prior the log analytics space had to exist
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.name
  //scope: resourceGroup(managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.subscriptionId, managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.resourceGroup)
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}


resource managedEnvironmentRes 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: managedEnvironment.name
  location: resourceGroup().location
  tags: tags
  properties: {
    appLogsConfiguration: {
      // Cannot be set to 'none', null acts as 'none'
      destination: !empty(managedEnvironment.logAnalyticsWorkspace.name) ? 'log-analytics' : managedEnvironment.enableAzureMonitorLogsDestination ? 'azure-monitor' : null
      logAnalyticsConfiguration: !empty(managedEnvironment.logAnalyticsWorkspace.name) ? {
        customerId: logAnalyticsWorkspace.id
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      } : null
    }
    daprAIConnectionString: !empty(managedEnvironment.daprApplicationInsights.name) ? daprAppInsights.properties.ConnectionString : ''
    daprAIInstrumentationKey: !empty(managedEnvironment.daprApplicationInsights.name) ? daprAppInsights.properties.InstrumentationKey : ''
    vnetConfiguration: {
      dockerBridgeCidr: managedEnvironment.virtualNetwork.dockerBridgeCidr
      platformReservedCidr: managedEnvironment.virtualNetwork.platformReservedCidr
      platformReservedDnsIP: managedEnvironment.virtualNetwork.dnsIp
      infrastructureSubnetId: !empty(managedEnvironment.virtualNetwork.infrastructureSubnet.name) ? infrastructureSubnet.id : null
      internal: managedEnvironment.virtualNetwork.internal
    }
    workloadProfiles: map(managedEnvironment.workloadProfiles, workloadProfile => {
      name: workloadProfile.name
      workloadProfileType: workloadProfile.type
      minimumCount: workloadProfile.minInstanceCount
      maximumCount: workloadProfile.maxInstanceCount
    })
    zoneRedundant: managedEnvironment.zoneRedundant
  }
}

var defaultStorage = {
  name: ''
  readOnly: false
  storageAccount: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
    shareName: ''
  }
}

resource storageAccounts 'Microsoft.Storage/storageAccounts@2023-04-01' existing = [for storage in managedEnvironment.storages: {
  name: storage.storageAccount.name
  scope: resourceGroup(union(defaultStorage, storage).storageAccount.subscriptionId, storage.storageAccount.resourceGroup)
}]

resource storages 'Microsoft.App/managedEnvironments/storages@2024-03-01' = [for (storage, i) in managedEnvironment.storages: {
  name: storage.name
  parent: managedEnvironmentRes
  properties: {
    azureFile: {
      accountKey: storageAccounts[i].listKeys().keys[0].value
      accountName: storage.storageAccount.name
      shareName: storage.storageAccount.shareName
      accessMode: union(defaultStorage, storage).readonly ? 'ReadOnly' : 'ReadWrite'
    }
  }
}]

var defaultDaprComponent = {
  name: ''
  type: ''
  version: ''
  ignoreErrors: false
  initTimeout: 0
  metadata: []
  scopes: []
  secrets: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
    secretName: ''
  }
}

resource daprSecretsKeyVaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = [for (daprComponent, i) in managedEnvironment.daprComponents: if (!empty(union(defaultDaprComponent, daprComponent).secrets.name)) {
  name: daprComponent.secrets.name
  scope: resourceGroup(union(defaultDaprComponent, daprComponent).secrets.subscriptionId, daprComponent.secrets.resourceGroup)
}]

module daprComponents 'dapr-component.bicep' = [for (daprComponent, i) in managedEnvironment.daprComponents: {
  name: 'daprComponent-${uniqueString(managedEnvironmentRes.name)}-${i}'
  params: {
    managedEnvironmentName: managedEnvironmentRes.name
    daprComponent: union(defaultDaprComponent, daprComponent)
    secrets: !empty(union(defaultDaprComponent, daprComponent).secrets.name)
     ? daprSecretsKeyVaults[i].getSecret(daprComponent.secrets.secretName)
     : ''
  }
}]

var defaultCertificate = {
  name: ''
  certificateData: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
    secretName: ''
  }
}

resource certificateDataKeyVaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = [for certificate in managedEnvironment.certificates: {
  name: certificate.certificateData.name
  scope: resourceGroup(union(defaultCertificate, certificate).certificateData.subscriptionId, certificate.certificateData.resourceGroup)
}]

module certificate 'managed-environment-certificate.bicep' = [for (certificate, i) in managedEnvironment.certificates: {
  name: 'certificate-${uniqueString(managedEnvironmentRes.name)}-${i}'
  params: {
    managedEnvironmentName: managedEnvironmentRes.name
    certificateName: certificate.name
    certificateData: certificateDataKeyVaults[i].getSecret(certificate.certificateData.secretName)
  }
}]



/*
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = if (!empty(managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.name)) {
  name: managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.name
  scope: resourceGroup(managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.subscriptionId, managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.resourceGroup)
}
*/

resource diagnosticSettingsLogAnalytics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.name)) {
  name: 'LogsAndMetricsToLogAnalytics'
  scope: managedEnvironmentRes
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    eventHubAuthorizationRuleId: null
    eventHubName: null
    logAnalyticsDestinationType: null
    marketplacePartnerId: null
    serviceBusRuleId: null
    storageAccountId: null
    logs: [for log in managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.enabledLogs: {
      category: log
      enabled: true
      categoryGroup: null
      retentionPolicy: {
        days: 0
        enabled: false
      }
    }]
    metrics: [for metric in managedEnvironment.diagnosticSettings.logAnalyticsWorkspace.enabledMetrics: {
      category: metric
      enabled: true
      retentionPolicy: {
        days: 0
        enabled: false
      }
      timeGrain: null
    }]
  }
}

resource eventHub 'Microsoft.EventHub/namespaces@2024-05-01-preview' existing = if (!empty(managedEnvironment.diagnosticSettings.eventHub.namespace)) {
  name: managedEnvironment.diagnosticSettings.eventHub.namespace
  scope: resourceGroup(managedEnvironment.diagnosticSettings.eventHub.subscriptionId, managedEnvironment.diagnosticSettings.eventHub.resourceGroup)
}

resource eventHubAuthorizationRule 'Microsoft.EventHub/namespaces/authorizationRules@2024-05-01-preview' existing = if (!empty(managedEnvironment.diagnosticSettings.eventHub.namespace)) {
  name: managedEnvironment.diagnosticSettings.eventHub.policyName
  parent: eventHub
}

resource diagnosticSettingsEventHub 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(managedEnvironment.diagnosticSettings.eventHub.namespace)) {
  name: 'LogsAndMetricsToEventHub'
  scope: managedEnvironmentRes
  properties: {
    eventHubAuthorizationRuleId: eventHubAuthorizationRule.id
    eventHubName: empty(managedEnvironment.diagnosticSettings.eventHub.name) ? null : managedEnvironment.diagnosticSettings.eventHub.name
    logAnalyticsDestinationType: null
    marketplacePartnerId: null
    serviceBusRuleId: null
    storageAccountId: null
    workspaceId: null
    logs: [for log in managedEnvironment.diagnosticSettings.eventHub.enabledLogs: {
      category: log
      enabled: true
      categoryGroup: null
      retentionPolicy: {
        days: 0
        enabled: false
      }
    }]
    metrics: [for metric in managedEnvironment.diagnosticSettings.eventHub.enabledMetrics: {
      category: metric
      enabled: true
      retentionPolicy: {
        days: 0
        enabled: false
      }
      timeGrain: null
    }]
  }
}

resource diagnosticsStorageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = if (!empty(managedEnvironment.diagnosticSettings.storageAccount.name)) {
  name: managedEnvironment.diagnosticSettings.storageAccount.name
  scope: resourceGroup(managedEnvironment.diagnosticSettings.storageAccount.subscriptionId, managedEnvironment.diagnosticSettings.storageAccount.resourceGroup)
}

var defaultRetention = {
  retentionInDays: 365
}

resource diagnosticSettingsStorageAccount 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(managedEnvironment.diagnosticSettings.storageAccount.name)) {
  name: 'LogsAndMetricsToStorageAccount'
  scope: managedEnvironmentRes
  properties: {
    storageAccountId: diagnosticsStorageAccount.id
    eventHubAuthorizationRuleId: null
    eventHubName: null
    workspaceId: null
    serviceBusRuleId: null
    marketplacePartnerId: null
    logAnalyticsDestinationType: null
    logs: [for log in managedEnvironment.diagnosticSettings.storageAccount.enabledLogs: {
      category: log.name
      enabled: true
      categoryGroup: null
      retentionPolicy: {
        days: union(defaultRetention, log).retentionInDays
        enabled: union(defaultRetention, log).retentionInDays != 0
      }
    }]
    metrics: [for metric in managedEnvironment.diagnosticSettings.storageAccount.enabledMetrics: {
      category: metric.name
      enabled: true
      retentionPolicy: {
        days: union(defaultRetention, metric).retentionInDays
        enabled: union(defaultRetention, metric).retentionInDays != 0
      }
      timeGrain: null
    }]
  }
}

output managedEnvironment object = {
  name: managedEnvironment.name
  ipAddress: managedEnvironmentRes.properties.staticIp
  defaultDomainName: managedEnvironmentRes.properties.defaultDomain
}
