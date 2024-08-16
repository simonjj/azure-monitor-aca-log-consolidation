param containerApps array
param tags object

var defaultContainerApp = {
  name: ''
  tags: {}
  enableIdentity: false
  userAssignedIdentities: []
  managedEnvironment: {
    resourceGroup: ''
    name: ''
  }
  workloadProfileName: null
  multipleActiveRevisions: false
  registries: []
  containers: []
  volumes: []
  dapr: {
    appId: ''
    port: 0
    protocol: 'http'
    enabled: false
  }
  secrets: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
    secretName: ''
  }
  ingress: {
    allowIngressTraffic: false
    allowInsecureTraffic: false
    isExternal: false
    traffic: []
    protocol: 'Auto'
    port: 80
    customDomains: []
  }
  scale: {
    minReplicas: 0
    maxReplicas: 10
    rules: []
  }
  revisionSuffix: ''
  authentication: {
    enabled: false
    excludedPaths: []
    unauthenticatedAction: 'Return401'
    defaultProvider: ''
    apple: {
      enabled: false
      scopes: []
      clientId: ''
      secretName: ''
    }
    azureActiveDirectory: {
      enabled: false
      disableAuthenticateRequest: false
      loginParameters: []
      openIdIssuerUri: ''
      clientId: ''
      secretName: ''
      certificateThumbprint: ''
      allowedAudiences: []
      allowedApplications: []
      allowedGroups: []
      allowedIdentities: []
      jwtClaims: {
        allowedClientApplications: []
        allowedGroups: []
      }
    }
    azureStaticWebApp: {
      enabled: false
      clientId: ''
    }
    facebook: {
      enabled: false
      scopes: []
      appId: ''
      secretName: ''
      graphApiVersion: ''
    }
    gitHub: {
      enabled: false
      scopes: []
      clientId: ''
      secretName: ''
    }
    google: {
      enabled: false
      scopes: []
      clientId: ''
      secretName: ''
      allowedAudiences: []
    }
    twitter: {
      enabled: false
      apiKey: ''
      secretName: ''
    }
    customOpenIdProviders: []
    allowedRedirectUrls: []
    cookieExpirationTime: ''
    nonce: {
      expiration: null
      validate: false
    }
    preserveUrlAfterLogin: false
    logoutEndpoint: null
  }
}

resource secretsKeyVaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = [for containerApp in containerApps: if (!empty(union(defaultContainerApp, containerApp).secrets.name)) {
  name: containerApp.secrets.name
  scope: resourceGroup(union(defaultContainerApp, containerApp).secrets.subscriptionId, containerApp.secrets.resourceGroup)
}]

module containerAppWithSecrets 'container-app.bicep' = [for (containerApp, i) in containerApps: {
  name: 'containerAppSecrets-${uniqueString(resourceGroup().name)}-${i}'
  params: {
    containerApp: union(defaultContainerApp, containerApp)
    secrets: !empty(union(defaultContainerApp, containerApp).secrets.name) ? secretsKeyVaults[i].getSecret(containerApp.secrets.secretName) : ''
    tags: union(tags, union(defaultContainerApp, containerApp).tags)
  }
}]


output containerApps array = [for (containerApp, i) in containerApps: containerAppWithSecrets[i].outputs.containerApp]
