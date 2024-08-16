param containerApp object
@secure()
param secrets string
param tags object

var defaultIdentity = {
  subscriptionId: subscription().subscriptionId
}

resource userAssignedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = [for userAssignedIdentity in containerApp.userAssignedIdentities: {
  name: userAssignedIdentity.name
  scope: resourceGroup(union(defaultIdentity, userAssignedIdentity).subscriptionId, userAssignedIdentity.resourceGroup)
}]

var userAssignedIdentitiesIds = [for (identity, i) in containerApp.userAssignedIdentities: userAssignedIdentities[i].id]

var defaultRegistry = {
  server: ''
  username: ''
  secretName: ''
  useIdentity: false
  userAssignedIdentity: {
    subscriptionId: subscription().subscriptionId
    resourceGroup: ''
    name: ''
  }
}

resource registryUserAssignedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = [for registry in containerApp.registries: if (!empty(union(defaultRegistry, registry).userAssignedIdentity.name)) {
  name: registry.userAssignedIdentity.name
  scope: resourceGroup(union(defaultRegistry, registry).userAssignedIdentity.subscriptionId, registry.userAssignedIdentity.resourceGroup)
}]

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerApp.managedEnvironment.name
  scope: resourceGroup(containerApp.managedEnvironment.resourceGroup)
}

var defaultCustomDomain = {
  hostname: ''
  enabled: true
  certificateName: ''
}

resource managedEnvironmentCertificates 'Microsoft.App/managedEnvironments/certificates@2024-03-01' existing = [for customDomain in containerApp.ingress.customDomains: {
  name: customDomain.certificateName
  parent: managedEnvironment
}]

var customDomains = [for (customDomain, i) in containerApp.ingress.customDomains: {
  bindingType: union(defaultCustomDomain, customDomain).enabled ? 'SniEnabled' : 'Disabled'
  certificateId: managedEnvironmentCertificates[i].id
  name: customDomain.hostname
}]

var defaultTraffic = {
  label: ''
  revisionName: ''
  weight: 0
}

var defaultTrafficArray = [
  {
    weight: 100
  }
]

var traffic = [for traffic in empty(containerApp.ingress.traffic) ? defaultTrafficArray : containerApp.ingress.traffic: {
  label: !empty(union(defaultTraffic, traffic).label) ? traffic.label : null
  weight: traffic.weight
  latestRevision: empty(union(defaultTraffic, traffic).revisionName)
  revisionName: !empty(union(defaultTraffic, traffic).revisionName) ? traffic.revisionName : null
}]

var defaultContainer = {
  name: ''
  image: ''
  cpu: '.25'
  memoryGi: '0.5'
  args: []
  command: []
  env: []
  volumeMounts: []
  probes: {
    liveness: {
      enabled: false
      transport: ''
      path: ''
      port: 0
      initialDelay: 0
      period: 10
      timeout: 1
      successThreshold: 1
      failureThreshold: 3
      httpHeaders: []
    }
    readiness: {
      enabled: false
      transport: ''
      path: ''
      port: 0
      initialDelay: 0
      period: 10
      timeout: 1
      successThreshold: 1
      failureThreshold: 3
      httpHeaders: []
    }
    startup: {
      enabled: false
      transport: ''
      path: ''
      port: 0
      initialDelay: 0
      period: 10
      timeout: 1
      successThreshold: 1
      failureThreshold: 3
      httpHeaders: []
    }
  }
}

var defaultVolume = {
  name: ''
  storageName: ''
}

var defaultScaleRule = {
  name: ''
  type: ''
  concurrentRequests: 0
  queueName: ''
  queueLength: 0
  auth: []
  metadata: {}
  customType: ''
}

resource containerAppRes 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerApp.name
  location: resourceGroup().location
  tags: tags
  identity: {
    type: containerApp.enableIdentity
      ? !empty(containerApp.userAssignedIdentities)
      ? 'SystemAssigned, UserAssigned'
      : 'SystemAssigned'
      : !empty(containerApp.userAssignedIdentities)
      ? 'UserAssigned'
      : 'None'
    userAssignedIdentities: empty(containerApp.userAssignedIdentities)
      ? null
      : json(replace(replace(replace(string(userAssignedIdentitiesIds), '",', '":{},'), '[', '{'), '"]', '":{}}'))
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      secrets: !empty(secrets) ? json(secrets) : []
      registries: [for (registry, i) in containerApp.registries: {
        identity: union(defaultRegistry, registry).useIdentity
          ? 'system'
          : !empty(union(defaultRegistry, registry).userAssignedIdentity.name)
          ? registryUserAssignedIdentities[i].id
          : null
        passwordSecretRef: !empty(union(defaultRegistry, registry).secretName) ? registry.secretName : null
        server: registry.server
        username: !empty(union(defaultRegistry, registry).secretName) ? registry.username : null
      }]
      ingress: containerApp.ingress.allowIngressTraffic ? {
        allowInsecure: containerApp.ingress.allowInsecureTraffic
        external: containerApp.ingress.isExternal
        transport: containerApp.ingress.protocol
        targetPort: containerApp.ingress.port
        customDomains: customDomains
        traffic: traffic
      } : null
      activeRevisionsMode: containerApp.multipleActiveRevisions ? 'Multiple' : 'Single'
      dapr: !empty(containerApp.dapr.appId) ? {
        appId: containerApp.dapr.appId
        appPort: containerApp.dapr.port > 0 ? containerApp.dapr.port : null
        appProtocol: containerApp.dapr.protocol
        enabled: containerApp.dapr.enabled
      } : null
    }
    template: {
      containers: [for (container, i) in containerApp.containers: {
        name: container.name
        image: container.image
        args: union(defaultContainer, container).args
        command: union(defaultContainer, container).command
        env: union(defaultContainer, container).env
        resources: {
          cpu: union(defaultContainer, container).cpu
          memory: '${union(defaultContainer, container).memoryGi}Gi'
        }
        volumeMounts: union(defaultContainer, container).volumeMounts
        probes: union(union(defaultContainer, container).probes.liveness.enabled ? [
          {
            type: 'Liveness'
            failureThreshold: union(defaultContainer, container).probes.liveness.failureThreshold
            successThreshold: union(defaultContainer, container).probes.liveness.successThreshold
            initialDelaySeconds: union(defaultContainer, container).probes.liveness.initialDelay
            periodSeconds: union(defaultContainer, container).probes.liveness.period
            timeoutSeconds: union(defaultContainer, container).probes.liveness.timeout
            tcpSocket: container.probes.liveness.transport =~ 'TCP' ? {
              port: container.probes.liveness.port
            } : null
            httpGet: contains(toLower(container.probes.liveness.transport), 'http') ? {
              scheme: container.probes.liveness.transport
              httpHeaders: union(defaultContainer, container).probes.liveness.httpHeaders
              path: first(union(defaultContainer, container).probes.liveness.path) == '/'
                ? union(defaultContainer, container).probes.liveness.path
                : '/${union(defaultContainer, container).probes.liveness.path}'
              port: union(defaultContainer, container).probes.liveness.port > 0
                ? container.probes.liveness.port
                : container.probes.liveness.transport =~ 'HTTP'
                ? 80
                : 443
            } : null
          }
        ] : [], union(defaultContainer, container).probes.readiness.enabled ? [
          {
            type: 'Readiness'
            failureThreshold: union(defaultContainer, container).probes.readiness.failureThreshold
            successThreshold: union(defaultContainer, container).probes.readiness.successThreshold
            initialDelaySeconds: union(defaultContainer, container).probes.readiness.initialDelay
            periodSeconds: union(defaultContainer, container).probes.readiness.period
            timeoutSeconds: union(defaultContainer, container).probes.readiness.timeout
            tcpSocket: container.probes.readiness.transport =~ 'TCP' ? {
              port: container.probes.readiness.port
            } : null
            httpGet: contains(toLower(container.probes.readiness.transport), 'http') ? {
              scheme: container.probes.readiness.transport
              httpHeaders: union(defaultContainer, container).probes.readiness.httpHeaders
              path: first(union(defaultContainer, container).probes.readiness.path) == '/'
                ? union(defaultContainer, container).probes.readiness.path
                : '/${union(defaultContainer, container).probes.readiness.path}'
              port: union(defaultContainer, container).probes.readiness.port > 0
                ? union(defaultContainer, container).probes.readiness.port
                : container.probes.readiness.transport =~ 'HTTP'
                ? 80
                : 443
            } : null
          }
        ] : [], union(defaultContainer, container).probes.startup.enabled ? [
          {
            type: 'Startup'
            failureThreshold: union(defaultContainer, container).probes.startup.failureThreshold
            successThreshold: union(defaultContainer, container).probes.startup.successThreshold
            initialDelaySeconds: union(defaultContainer, container).probes.startup.initialDelay
            periodSeconds: union(defaultContainer, container).probes.startup.period
            timeoutSeconds: union(defaultContainer, container).probes.startup.timeout
            tcpSocket: container.probes.startup.transport =~ 'TCP' ? {
              port: container.probes.startup.port
            } : null
            httpGet: contains(toLower(container.probes.startup.transport), 'http') ? {
              scheme: container.probes.startup.transport
              httpHeaders: union(defaultContainer, container).probes.startup.httpHeaders
              path: first(union(defaultContainer, container).probes.startup.path) == '/'
                ? union(defaultContainer, container).probes.startup.path
                : '/${union(defaultContainer, container).probes.startup.path}'
              port: union(defaultContainer, container).probes.startup.port > 0
                ? union(defaultContainer, container).probes.startup.port
                : container.probes.startup.transport =~ 'HTTP'
                ? 80
                : 443
            } : null
          }
        ] : [])
      }]
      scale: {
        minReplicas: containerApp.scale.minReplicas
        maxReplicas:containerApp.scale.maxReplicas
        rules: [for rule in containerApp.scale.rules: {
          name: rule.name
          http: rule.type =~ 'HTTP' ? {
            auth: union(rule, defaultScaleRule).auth
            metadata: union({
              concurrentRequests: string(rule.concurrentRequests)
            }, union(defaultScaleRule, rule).metadata)
          } : null
          azureQueue: rule.type =~ 'AzureQueue' ? {
            auth: union(rule, defaultScaleRule).auth
            queueName: rule.queueName
            queueLength: rule.queueLength
          } : null
          custom: rule.type =~ 'Custom' ? {
            auth: union(rule, defaultScaleRule).auth
            metadata: union(defaultScaleRule, rule).metadata
            type: rule.customType
          } : null
        }]
      }
      revisionSuffix: containerApp.revisionSuffix
      volumes: [for volume in containerApp.volumes: {
        name: volume.name
        storageName: !empty(union(defaultVolume, volume).storageName) ? volume.storageName : null
        storageType: empty(union(defaultVolume, volume).storageName) ? 'EmptyDir' : 'AzureFile'
      }]
    }
    workloadProfileName: !empty(containerApp.workloadProfileName) ? containerApp.workloadProfileName : null
  }
}

var defaultCustomOpenIdProvider = {
  name: ''
  clientId: ''
  secretName: ''
  metadataUri: null
  authorizationEndpoint: null
  tokenEndpoint: null
  issuerUri: null
  certificationUri: null
}

resource authenticationSettings 'Microsoft.App/containerApps/authConfigs@2024-03-01' = {
  name: 'current'
  parent: containerAppRes
  properties: {
    platform: {
      enabled: containerApp.authentication.enabled
    }
    globalValidation: containerApp.authentication.enabled ? {
      excludedPaths: containerApp.authentication.excludedPaths
      unauthenticatedClientAction: containerApp.authentication.unauthenticatedAction
      redirectToProvider: containerApp.authentication.unauthenticatedAction =~ 'RedirectToLoginPage' ? containerApp.authentication.defaultProvider : null
    } : null
    login: {
      allowedExternalRedirectUrls: containerApp.authentication.allowedRedirectUrls
      cookieExpiration: {
        convention: !empty(containerApp.authentication.cookieExpirationTime) ? 'FixedTime' : 'IdentityProviderDerived'
        timeToExpiration: !empty(containerApp.authentication.cookieExpirationTime) ? containerApp.authentication.cookieExpirationTime : null
      }
      nonce: {
        nonceExpirationInterval: containerApp.authentication.nonce.expiration
        validateNonce: containerApp.authentication.nonce.validate
      }
      preserveUrlFragmentsForLogins: containerApp.authentication.preserveUrlAfterLogin
      routes: {
        logoutEndpoint: containerApp.authentication.logoutEndpoint
      }
    }
    identityProviders: {
      apple: {
        enabled: containerApp.authentication.apple.enabled
        login: {
          scopes: containerApp.authentication.apple.scopes
        }
        registration: {
          clientId: containerApp.authentication.apple.clientId
          clientSecretSettingName: containerApp.authentication.apple.secretName
        }
      }
      azureActiveDirectory: {
        enabled: containerApp.authentication.azureActiveDirectory.enabled
        registration: {
          openIdIssuer: empty(containerApp.authentication.azureActiveDirectory.openIdIssuerUri)
            ? 'https://sts.windows.net/${subscription().tenantId}/v2.0'
            : containerApp.authentication.azureActiveDirectory.openIdIssuerUri
          clientId: containerApp.authentication.azureActiveDirectory.clientId
          clientSecretSettingName: containerApp.authentication.azureActiveDirectory.secretName
          clientSecretCertificateThumbprint: containerApp.authentication.azureActiveDirectory.certificateThumbprint
        }
        login: {
          disableWWWAuthenticate: containerApp.authentication.azureActiveDirectory.disableAuthenticateRequest
          loginParameters: containerApp.authentication.azureActiveDirectory.loginParameters
        }
        validation: {
          allowedAudiences: containerApp.authentication.azureActiveDirectory.allowedAudiences
          defaultAuthorizationPolicy: {
            allowedApplications: containerApp.authentication.azureActiveDirectory.allowedApplications
            allowedPrincipals: {
              groups: containerApp.authentication.azureActiveDirectory.allowedGroups
              identities: containerApp.authentication.azureActiveDirectory.allowedIdentities
            }
          }
          jwtClaimChecks: {
            allowedClientApplications: containerApp.authentication.azureActiveDirectory.jwtClaims.allowedClientApplications
            allowedGroups: containerApp.authentication.azureActiveDirectory.jwtClaims.allowedGroups
          }
        }
      }
      azureStaticWebApps: {
        enabled: containerApp.authentication.azureStaticWebApp.enabled
        registration: {
          clientId: containerApp.authentication.azureStaticWebApp.clientId
        }
      }
      facebook: {
        enabled: containerApp.authentication.facebook.enabled
        graphApiVersion: containerApp.authentication.facebook.graphApiVersion
        login: {
          scopes: containerApp.authentication.facebook.scopes
        }
        registration: {
          appId: containerApp.authentication.facebook.appId
          appSecretSettingName: containerApp.authentication.facebook.secretName
        }
      }
      gitHub: {
        enabled: containerApp.authentication.gitHub.enabled
        login: {
          scopes: containerApp.authentication.gitHub.scopes
        }
        registration: {
          clientId: containerApp.authentication.gitHub.clientId
          clientSecretSettingName: containerApp.authentication.gitHub.secretName
        }
      }
      google: {
        enabled: containerApp.authentication.google.enabled
        login: {
          scopes: containerApp.authentication.google.scopes
        }
        registration: {
          clientId: containerApp.authentication.google.clientId
          clientSecretSettingName: containerApp.authentication.google.secretName
        }
        validation: {
          allowedAudiences: containerApp.authentication.google.allowedAudiences
        }
      }
      twitter: {
        enabled: containerApp.authentication.twitter.enabled
        registration: {
          consumerKey: containerApp.authentication.twitter.apiKey
          consumerSecretSettingName: containerApp.authentication.twitter.secretName
        }
      }
      customOpenIdConnectProviders: reduce(map(containerApp.authentication.customOpenIdProviders, openIdProvider => {
        '${openIdProvider.name}': {
          registration: {
            clientId: openIdProvider.clientId
            clientCredential: {
              clientSecretSettingName: openIdProvider.secretName
            }
            openIdConnectConfiguration: {
              wellKnownOpenIdConfiguration: union(defaultCustomOpenIdProvider, openIdProvider).metadataUri
              authorizationEndpoint: union(defaultCustomOpenIdProvider, openIdProvider).authorizationEndpoint
              tokenEndpoint: union(defaultCustomOpenIdProvider, openIdProvider).tokenEndpoint
              issuer: union(defaultCustomOpenIdProvider, openIdProvider).issuerUri
              certificationUri: union(defaultCustomOpenIdProvider, openIdProvider).certificationUri
            }
          }
        }
      }), {}, (cur, next) => union(cur, next))
    }
  }
}

output containerApp object = {
  name: containerApp.name
  identity: {
    type: containerApp.enableIdentity || !empty(containerApp.userAssignedIdentities) ? containerAppRes.identity.type : 'None'
    principalId: containerApp.enableIdentity ? containerAppRes.identity.principalId : ''
    tenantId: containerApp.enableIdentity ? containerAppRes.identity.tenantId : subscription().tenantId
  }
  outboundIpAddresses: containerAppRes.properties.outboundIpAddresses
  customDomainVerificationId: containerAppRes.properties.customDomainVerificationId
}
