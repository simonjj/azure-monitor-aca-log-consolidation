param managedEnvironmentName string
param certificateName string
@secure()
param certificateData string

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: managedEnvironmentName
}

resource certificate 'Microsoft.App/managedEnvironments/certificates@2024-03-01' = {
  name: certificateName
  location: resourceGroup().location
  parent: managedEnvironment
  properties: {
    value: certificateData
  }
}
