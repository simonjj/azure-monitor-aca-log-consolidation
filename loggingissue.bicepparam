using 'main.bicep'

param resourceGroups = [
  {
    name: 'loggingissuerg'
    location: 'eastus'
    managedEnvironments: [
      {
        name: 'loggingissuenv'
        enableAzureMonitorLogsDestination: true
        diagnosticSettings: {
          logAnalyticsWorkspace: {
            subscriptionId: 'your-subscription-id'
            resourceGroup: 'loggingissuerg'
            name: 'loggingissue-space'
            enabledLogs: [
              'ContainerAppConsoleLogs'
              'ContainerAppSystemLogs'
              'AppEnvSpringAppConsoleLogs'
            ]
            enabledMetrics: [
              'AllMetrics'
            ]
          }
        }
      }
    ]
    containerApps: [
      {
        name: 'loggingissueapp'
        managedEnvironment: {
          resourceGroup: 'loggingissuerg'
          name: 'loggingissuenv'
        }
// TODO1 He doesn't allow ingress on his first container app. However, he says he still sees system logs, they just aren't sent to the Log Analytics workspace.
        ingress: {
          allowIngressTraffic: true
        }
        containers: [
          {
            name: 'loggingissueapp'
            image: 'mcr.microsoft.com/k8se/quickstart:latest'
            probes: {
              liveness: {
                enabled: true
                transport: 'HTTP'
              }
            }
          }
        ]
      }
    ]
  }
]
