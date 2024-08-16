param managedEnvironmentName string
param daprComponent object
@secure()
param secrets string

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: managedEnvironmentName
}

resource daprComponentRes 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
  name: daprComponent.name
  parent: managedEnvironment
  properties: {
    componentType: daprComponent.type
    version: daprComponent.version
    ignoreErrors: daprComponent.ignoreErrors
    secrets: !empty(secrets) ? json(secrets) : []
    metadata: daprComponent.metadata
    scopes: daprComponent.scopes
    initTimeout: string(daprComponent.initTimeout)
  }
}
