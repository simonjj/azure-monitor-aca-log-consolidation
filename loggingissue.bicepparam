using 'main2.bicep'

param resourceGroups = [
  {
    name: 'mvploggingissue2'
    location: 'northeurope'
    managedEnvironments: [
      {
        name: 'mvploggingissue2'
        enableAzureMonitorLogsDestination: true
        diagnosticSettings: {
          logAnalyticsWorkspace: {
            // subscription here is unnecessary but I was lazy to change to a dynamic model in managed-environment.bicep
            subscriptionId: '30501c6c-81f6-41ac-a388-d29cf43a020d'
            resourceGroup: 'mvploggingissue2'
            name: 'mvploganalytics2-space'
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
        name: 'mvloggingissuetest2'
        managedEnvironment: {
          resourceGroup: 'mvploggingissue2'
          name: 'mvploggingissue2'
        }
// TODO1 He doesn't allow ingress on his first container app. However, he says he still sees system logs, they just aren't sent to the Log Analytics workspace.
        ingress: {
          allowIngressTraffic: false
        }
        containers: [
          {
            name: 'logspewer'
            // This image might no longer be available because I lost access to this registry
            image: 'simonj.azurecr.io/logger-test'
            probes: {
              liveness: {
                enabled: false
                transport: 'HTTP'
              }
            }
          }
        ]
      }
    ]
  }
]
