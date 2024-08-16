@export()
type resourceGroup = {
  @description('The name of the resource group.')
  @minLength(1)
  @maxLength(90)
  name: string
  @description('The location of the resource group and resources within it.')
  location: string
  @description('''Enables creation of the resource group and applying the tags on it.
    Value false assumes the resource group already exists and its tags should not be overwritten.
    Allows scenario where multiple solutions deploy to same resource group. Default value: **true**.''')
  create: bool?
  @description('Tag name and value pairs to be applied. The tags applied on current level are inherited on everything down below.')
  tags: tagsType?
  @description('Container Apps Environments to deploy.')
  managedEnvironments: managedEnvironment[]?
  @description('Container Apps to deploy.')
  containerApps: containerApp[]?
}

type managedEnvironment = {
  @description('The name of the Container App environment.')
  name: string
  @description('Tag name and value pairs to be applied. The tags applied on current level are inherited on everything down below.')
  tags: tagsType?
  @description('''Log Analytics workspace where the managed environment will write its logs to.
    logAnalyticsWorkspace parameter takes precedence over enableAzureMonitorLogsDestination parameter.
    You can enable only one of them. If both are disabled logs are just streamed and not routed anywhere.''')
  logAnalyticsWorkspace: resourceReference?
  @description('''Enables routing logs to diagnostic settings so they can be sent to other destinations when configured.
    logAnalyticsWorkspace parameter takes precedence over enableAzureMonitorLogsDestination parameter.
    You can enable only one of them. If both are disabled logs are just streamed and not routed anywhere.
    Default value: **true**.''')
  enableAzureMonitorLogsDestination: bool?
  @description('Virtual network settings.')
  virtualNetwork: virtualNetwork?
  @description('Enables zone redundancy. Requires virtual network integration. Default value: **false**.')
  zoneRedundant: bool?
  @description('Workload profiles to configure. Consumption type profile is automatically present.')
  workloadProfiles: workloadProfile[]?
  @description('''[Dapr (Distributed Application Runtime)](https://docs.dapr.io/concepts/overview/) components to configure.
    [Learn more](https://docs.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cbicep).''')
  daprComponents: daprComponent[]?
  @description('Application Insights instance used by Dapr to export Service to Service communication telemetry.')
  daprApplicationInsights: resourceReference?
  @description('Private key certificates to be configured. These certificates can be used by container apps for custom hostnames.')
  certificates: certificate[]?
  @description('Azure File Shares that can be used as storage by container apps.')
  storages: storage[]?
  @description('Configure diagnostic settings to send logs and metrics from the resource to different stores / data processors.')
  diagnosticSettings: diagnosticSettings?
}

type virtualNetwork = {
  @description('Virtual Network subnet for the managed environment infrastructure components and user app containers. Minimum supported subnet size is /23.')
  infrastructureSubnet: infrastructureSubnet?
  @description('Disables internet-facing endpoints. Requires infrastructureSubnet to be configured. Default value: **false**.')
  internal: bool?
  @description('IP range to use for Docker bridge networking in CIDR notation. Must not overlap with any other provided IP ranges.')
  dockerBridgeCidr: string?
  @description('IP range reserved for environment infrastructure IP addresses in CIDR notation. Must not overlap with any other provided IP ranges.')
  platformReservedCidr: string?
  @description('IP address from the IP range defined by platformReservedCidr that will be reserved for the internal DNS server.')
  dnsIp: string?
}

type infrastructureSubnet = {
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
  @description('The name of the subnet.')
  subnetName: string
}

type workloadProfile = {
  @description('The name of the workload profile.')
  name: string
  @description('The type of the workload profile. [Available type names](https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles-overview).')
  type: string
  @description('Minimum profile instances to be available for the autoscaling.')
  @minValue(0)
  minInstanceCount: int
  @description('Maximum profile instances to be available for the autoscaling. Should be higher than minInstanceCount.')
  @minValue(1)
  maxInstanceCount: int
}

type daprComponent = {
  @description('The name of the component.')
  name: string
  @description('The type of component.')
  type: string
  @description('The version of the component.')
  version: string
  @description('Enables ignoring component errors. Default value: **false**.')
  ignoreErrors: bool?
  @description('The initialization timeout of the component. Value 0 stands for no timeout. Default value: **0**.')
  initTimeout: int?
  @description('Metadata of the component. Either value or secretRef must be configured.')
  metadata: metadata[]?
  @description('''Multiple secrets stored in JSON format as secret on Key Vault.
    The format of the JSON is the following the following:

  ```
  [
    {
      "name": "string",
      "value": "string"
    }
  ]
  ```

  It is worth noting that updating the secrets in Key Vault will not update the secrets in the resources unless redeployed,
  and that redeploy will remove any secrets that are configured on the resources that are not in the Key Vault's secret.''')
  secrets: keyVaultSecretReference?
  @description('Container App names that can use the Dapr component.')
  scopes: string[]?
}

type metadata = {
  @description('The name of the metadata property.')
  name: string
  @description('The value of the property.')
  value: string?
  @description('The name of the secret from the JSON contained in resourceGroups.managedEnvironments.daprComponents.secrets.secretName.')
  secretRef: string?
}

type certificate = {
  @description('The name of the certificate to be used for reference in container apps.')
  name: string
  @description('Private key certificate stored in Key Vault.')
  certificateData: keyVaultSecretReference
}

type storage = {
  @description('The name of the storage to be used as reference in container apps.')
  name: string
  @description('Mounts the share as read-only. Default value: **false**.')
  readOnly: bool?
  @description('Azure File share to use.. Access to the storage account uses account key, so key access has to be enabled on the account.')
  storageAccount: storageAccount
}

type storageAccount = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
  @description('The name of the share.')
  shareName: string
}

type keyVaultSecretReference = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
  @description('The name of the secret.')
  secretName: string
}

type diagnosticSettings = {
  @description('Send logs and metrics to existing Log Analytics workspace.')
  logAnalyticsWorkspace: diagnosticSettingLogsAnalytics?
  @description('''Send logs and metrics to existing Event Hub namespace.
    The Event Hub needs to be in the same region as the resource. If resource is global, it can be in any region.''')
  eventHub: diagnosticSettingEventHub?
  @description('''Send logs and metrics to existing Storage Account.
    The Storage Account needs to be in the same region as the resource. If resource is global, it can be in any region.''')
  storageAccount: diagnosticSettingStorageAccount?
}

type diagnosticSettingLogsAnalytics = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
  @description('''The names of logs to be sent. Available logs are ContainerAppConsoleLogs, ContainerAppSystemLogs, AppEnvSpringAppConsoleLogs.
    By default, no logs are sent, and you need to configure explicitly the ones you want to send.''')
  enabledLogs: string[]?
  @description(''''The names of metrics to be sent. Available metrics are AllMetrics.
    By default, no metrics are sent, and you need to configure explicitly the ones you want to send.''')
  enabledMetrics: string[]?
}

type diagnosticSettingEventHub = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The namespace of the Event Hub.')
  namespace: string
  @description('The name of the Event Hub. Default value: **automatically created by the service**.')
  name: string?
  @description('''The name of the authorization policy to be used to write to the Event Hub.
    Recommendation is to create separate authorization policy if the Event Hub namespace is used for other purposes besides diagnostic settings integration.
    This policy requires allowing at least Manage and Listen access.
    Default value: **RootManageSharedAccessKey**.''')
  policyName: string?
  @description('''The names of logs to be sent. Available logs are ContainerAppConsoleLogs, ContainerAppSystemLogs, AppEnvSpringAppConsoleLogs.
    By default, no logs are sent, and you need to configure explicitly the ones you want to send.''')
  enabledLogs: string[]?
  @description(''''The names of metrics to be sent. Available metrics are AllMetrics.
    By default, no metrics are sent, and you need to configure explicitly the ones you want to send.''')
  enabledMetrics: string[]?
}

type diagnosticSettingStorageAccount = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
  @description('''Configures which logs to be enabled.
    By default, no logs are sent, and you need to configure explicitly the ones you want to send.''')
  enabledLogs: storageLog[]?
  @description(''''Configures which metrics to be enabled.
    By default, no metrics are sent, and you need to configure explicitly the ones you want to send.''')
  enabledMetrics: storageMetric[]?
}

type storageLog = {
  @description('The name of the log. Available logs are ContainerAppConsoleLogs, ContainerAppSystemLogs, AppEnvSpringAppConsoleLogs.')
  name: string
  @description('Retention policy. If you do not want to apply any retention policy and retain data forever, set retention (days) to 0. Default value: **365**.')
  @minValue(0)
  @maxValue(365)
  retentionInDays: int?
}

type storageMetric = {
  @description('The name of the metric. Available metrics are AllMetrics.')
  name: string
  @description('Retention policy. If you do not want to apply any retention policy and retain data forever, set retention (days) to 0. Default value: **365**.')
  @minValue(0)
  @maxValue(365)
  retentionInDays: int?
}

type containerApp = {
  @description('The name of the Container App.')
  name: string
  @description('Tag name and value pairs to be applied. The tags applied on current level are inherited on everything down below.')
  tags: tagsType?
  @description('Enables the system assigned identity. Default value: **false**.')
  enableIdentity: bool?
  @description('Assigns user assigned identities to the resource.')
  userAssignedIdentities: resourceReference[]?
  @description('The Container app environment of the container app.')
  managedEnvironment: resourceReferenceNoSub
  @description('Enables multiple active revisions. When disabled only the latest revision will be active. Default value: **false**.')
  multipleActiveRevisions: bool?
  @description('The user-friendly suffix to use for revision names.')
  revisionSuffix: string?
  @description('The workload profile name. Default value: **null**.')
  workloadProfileName: string?
  @description('''Multiple secrets stored in JSON format as secret on Key Vault.
    The format of the JSON is the following the following:

  ```
  [
    {
      "name": "string",
      "value": "string"
    }
  ]
  ```

  It is worth noting that updating the secrets in Key Vault will not update the secrets in the resources unless redeployed,
  and that redeploy will remove any secrets that are configured on the resources that are not in the Key Vault's secret.''')
  secrets: keyVaultSecretReference?
  @description('Private container registries to be available for the container app. Either username and secretName, useIdentity or userAssignedIdentity must be configured.')
  registries: registry[]?
  @description('Ingress traffic settings for application needing HTTP endpoint.')
  ingress: ingress?
  @description('Volumes available to mount to the containers.')
  volumes: volume[]?
  @description('Containers to deploy.')
  containers: container[]
  @description('Configures [Dapr (Distributed Application Runtime)](https://docs.dapr.io/concepts/overview/).')
  dapr: dapr?
  @description('Scaling configuration.')
  scale: scale?
  @description('Authentication settings.')
  authentication: authentication?
}

type registry = {
  @description('The hostname of the registry.')
  server: string
  @description('The username to authenticate to the registry.')
  username: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('Enables using the system assigned identity to authenticate to the registry. Default value: **false**.')
  useIdentity: bool?
  @description('Uses user assigned identity to authenticate to the registry.')
  userAssignedIdentity: resourceReference?
}

type ingress = {
  @description('Allows HTTP ingress traffic. Default value: **false**.')
  allowIngressTraffic: bool?
  @description('Allows unencrypted HTTP traffic. Default value: **false**.')
  allowInsecureTraffic: bool?
  @description('Allows traffic from internet sources. Default value: **false**.')
  isExternal: bool?
  @description('The HTTP version to use. Default value: **Auto**.')
  protocol: 'Auto' | 'HTTP' | 'HTTP2'?
  @description('''The container's port to send the ingress traffic to. Default value: **80**.''')
  port: int?
  @description('Custom domains to configure.')
  customDomains: customDomain[]?
  @description('Configures traffic distribution among revisions. Default value: **all traffic to the latest revision**.')
  traffic: traffic[]?
}

type customDomain = {
  @description('The FQDN.')
  hostname: string
  @description('Enables the hostname binding. Default value: **true**.')
  enabled: bool?
  @description('The name of the certificate deployed via resourceGroups.managedEnvironments.certificates.name.')
  certificateName: string
}

type traffic = {
  @description('Traffic label to apply to a revision.')
  label: string
  @description('The name of the revision to direct traffic to. Default value: **latest revision**.')
  revisionName: string?
  @description('The percentage of traffic to send to this revision. All configured weights need to add up to 100.')
  @minValue(0)
  @maxValue(100)
  weight: int
}

type volume = {
  @description('The volume name.')
  name: string
  @description('''The name of the storage configured via resourceGroups.managedEnvironments.storages.name.
    Default value: **volume is mounted as empty directory**.''')
  storageName: string?
}

type container = {
  @description('Friendly name of the container.')
  name: string
  @description('''The image identifier in the form of \<container registry fqdn>\/\<container image identifier\>:\<revision\>.''')
  image: string
  @description('''The CPU cores to provide to the container.
    The smallest unit of CPU that can be assigned to a single container is 0.25 or a multiple thereof.
    Total CPU and memory for all containers in a container app must add up to one of the following combinations: cpu: 0.25, memory: 0.5Gi; cpu: 0.5, memory: 1.0Gi;
    cpu: 0.75, memory: 1.5Gi; cpu: 1.0, memory: 2.0Gi; cpu: 1.25, memory: 2.5Gi; cpu: 1.5, memory: 3.0Gi; cpu: 1.75, memory: 3.5Gi; cpu: 2.0, memory: 4.0Gi.
    Default value: **0.25**.''')
  cpu: string?
  @description('The memory in gigabytes to provide to the container. For allowed values, see cpu description. Default value: **0.5**.')
  memoryGi: string?
  @description('''Strings to pass as a single startup command to the container.
    Default value: **default startup command**.''')
  command: string[]?
  @description('Arguments to pass to the container upon startup.')
  args: string[]?
  @description('Environment variables. Either value or secretRef must be configured.')
  env: env[]?
  @description('Volumes to mount on the container.')
  volumeMounts: volumeMount[]?
  @description('Configures probes.')
  probes: probes?
}

type env = {
  @description('The name of the environment variable.')
  name: string
  @description('Plain text value of the environment variable.')
  value: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretRef: string?
}

type volumeMount = {
  @description('The path in the container where the volume will be mounted.')
  mountPath: string
  @description('The name of the volume configured in resourceGroups.containerApps.volumes.name.')
  volumeName: string
}

type probes = {
  @description('Liveness probe.')
  liveness: probe?
  @description('Readiness probe.')
  readiness: probe?
  @description('Startup probe.')
  startup: probe?
}

@discriminator('transport')
type probe = probeHttp | probeTcp | probeHttps

type probeHttp = {
  @description('Enables the probe. Default value: **false**.')
  enabled: bool?
  @description('The transport protocol.')
  transport: 'HTTP'
  @description('The port to use. Default value: **80**.')
  port: int?
  @description('The HTTP path to attempt to GET. Default value: **/**.')
  path: string?
  @description('The number of seconds elapsed after the container has started before the probe is initiated. Default value: **0**.')
  initialDelay: int?
  @description('Recurrence of the probe in seconds. Default value: **10**.')
  period: int?
  @description('Timeout of the probe in seconds. Default value: **1**.')
  timeout: int?
  @description('Minimum consecutive successes for the probe to be considered successful after failure. Default value: **1**.')
  successThreshold: int?
  @description('Minimum consecutive failures for the probe to be considered failed after having succeeded. Default value: **3**.')
  failureThreshold: int?
  @description('Custom headers to set in the request. HTTP allows repeated headers.')
  httpHeaders: httpHeader[]?
}

type probeHttps = {
  @description('Enables the probe. Default value: **false**.')
  enabled: bool?
  @description('The transport protocol.')
  transport: 'HTTPS'
  @description('The port to use. Default value: **443**.')
  port: int?
  @description('The HTTP path to attempt to GET. Default value: **/**.')
  path: string?
  @description('The number of seconds elapsed after the container has started before the probe is initiated. Default value: **0**.')
  initialDelay: int?
  @description('Recurrence of the probe in seconds. Default value: **10**.')
  period: int?
  @description('Timeout of the probe in seconds. Default value: **1**.')
  timeout: int?
  @description('Minimum consecutive successes for the probe to be considered successful after failure. Default value: **1**.')
  successThreshold: int?
  @description('Minimum consecutive failures for the probe to be considered failed after having succeeded. Default value: **3**.')
  failureThreshold: int?
  @description('Custom headers to set in the request. HTTP allows repeated headers.')
  httpHeaders: httpHeader[]?
}

type probeTcp = {
  @description('Enables the probe. Default value: **false**.')
  enabled: bool?
  @description('The transport protocol.')
  transport: 'TCP'
  @description('The port to use.')
  port: int
  @description('The number of seconds elapsed after the container has started before the probe is initiated. Default value: **0**.')
  initialDelay: int?
  @description('Recurrence of the probe in seconds. Default value: **10**.')
  period: int?
  @description('Timeout of the probe in seconds. Default value: **1**.')
  timeout: int?
  @description('Minimum consecutive successes for the probe to be considered successful after failure. Default value: **1**.')
  successThreshold: int?
  @description('Minimum consecutive failures for the probe to be considered failed after having succeeded. Default value: **3**.')
  failureThreshold: int?
}

type httpHeader = {
  @description('The name of the header.')
  name: string
  @description('The value of the header.')
  value: string
}

type dapr = {
  @description('Dapr application identifier.')
  appId: string
  @description('The port your application is listening on. Default value: **null**.')
  port: int?
  @description('The protocol of your application. Default value: **http**.')
  protocol: 'http' | 'grpc'?
  @description('Enables Dapr side car. Default value: **false**.')
  enabled: bool?
}

type scale = {
  @description('The minimum number of instances. Default value: **0**.')
  minReplicas: int?
  @description('The maximum number of instances. Default value: **10**.')
  maxReplicas: int?
  @description('Scaling rules to define how the scaling should be done. [Learn more](https://docs.microsoft.com/en-us/azure/container-apps/scale-app).')
  rules: rule[]?
}

@discriminator('type')
type rule = ruleHTTP | ruleAzureQueue | ruleCustom

type ruleHTTP = {
  @description('The name of the rule.')
  name: string
  @description('The type of the rule.')
  type: 'HTTP'
  @description('The number of concurrent requests per instance to aspire to.')
  concurrentRequests: int
  @description('Auth secrets to use to authenticate resources.')
  auth: auth[]?
  @description('Metadata properties to describe http scale rule.')
  metadata: ruleMetadata?
}

type ruleAzureQueue = {
  @description('The name of the rule.')
  name: string
  @description('The type of the rule.')
  type: 'AzureQueue'
  @description('The name of the Azure queue to gauge for container app scaling.')
  queueName: string
  @description('The queue length to aspire to.')
  queueLength: int
  @description('Auth secrets to use to authenticate resources.')
  auth: auth[]?
}

type ruleCustom = {
  @description('The name of the rule.')
  name: string
  @description('The type of the rule.')
  type: 'Custom'
  @description('Auth secrets to use to authenticate resources.')
  auth: auth[]?
  @description('The type of custom rule. [Available types](https://learn.microsoft.com/en-us/azure/container-apps/scale-app?pivots=azure-cli#custom).')
  customType: string
  @description('Metadata properties to describe http scale rule.')
  metadata: ruleMetadata?
}

type auth = {
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretRef: string
  @description('Trigger Parameter that uses the secret.')
  triggerParameter: string
}

type ruleMetadata = {
  @description('The value of the metadata property.')
  *: string
}

type authentication = {
  @description('Enables external authentication. Default value: **false**.')
  enabled: bool?
  @description('The paths that can be accessed without authenticating.')
  excludedPaths: string[]?
  @description('Action to take on an unauthenticated user. Default value: **Return401**.')
  unauthenticatedAction: 'AllowAnonymous' | 'RedirectToLoginPage' | 'Return401' | 'Return403'?
  @description('The default authentication provider to use when redirecting to the login page. Required when unauthenticatedAction is set to RedirectToLoginPage.')
  defaultProvider: string?
  @description('''External URLs that can be redirected to as part of logging in or logging out of the app.
    Note that the query string part of the URL is ignored.
    This is an advanced setting typically only needed by Windows Store application backends.
    Note that URLs within the current domain are always implicitly allowed.''')
  allowedRedirectUrls: string[]?
  @description('Enables preserving fragments from the request after the login request is made. Default value: **false**.')
  preserveUrlAfterLogin: bool?
  @description('The endpoint at which a logout request should be made.')
  logoutEndpoint: string?
  @description('''The time before the authentication cookie expires in HH:mm. Default value: **the identity provider's default**.''')
  @minLength(5)
  @maxLength(5)
  cookieExpirationTime: string?
  @description('The configuration settings of the nonce used in the login flow.')
  nonce: nonce?
  @description('Apple identity provider.')
  apple: apple?
  @description('Microsoft Entra identity provider. Either secretName or certificateThumbprint need to be configured.')
  azureActiveDirectory: azureActiveDirectory?
  @description('Azure Static Web App identity provider.')
  azureStaticWebApp: azureStaticWebApp?
  @description('Facebook identity provider.')
  facebook: facebook?
  @description('GitHub identity provider.')
  gitHub: gitHub?
  @description('Google identity provider.')
  google: google?
  @description('Twitter/X identity provider.')
  twitter: twitter?
  @description('Custom OpenID providers. Either metadataUri or issuerUri need to be configured.')
  customOpenIdProviders: customOpenIdProvider[]?
}

type nonce = {
  @description('The time after the request is made when the nonce should expire.')
  expiration: string
  @description('Enables validation of nonce as part of the login flow. Default value: **false**.')
  validate: bool?
}

type apple = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The client ID of the app used to login.')
  clientId: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('Scopes that should be requested while authenticating.')
  scopes: string[]?
}

type azureActiveDirectory = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The client ID of the app used to login.')
  clientId: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('Thumbprint of the certificate to use for authenticating the client ID.')
  certificateThumbprint: string?
  @description('''The OpenID Connect Issuer URI that represents the entity which issues access tokens for this application.
    Default value: **https://sts.windows.net/<tenantId\>/v2.0**.''')
  openIdIssuerUri: string?
  @description('Enables omitting www-authenticate provider from the request. Default value: **false**.')
  disableAuthenticateRequest: bool?
  @description('Login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".')
  loginParameters: string[]?
  @description('Audiences that can make successful authentication/authorization requests.')
  allowedAudiences: string[]?
  @description('Microsoft Entra allowed applications.')
  allowedApplications: string[]?
  @description('Microsoft Entra allowed groups.')
  allowedGroups: string[]?
  @description('Allowed identities/users.')
  allowedIdentities: string[]?
  @description('Checks that should be made while validating the JWT Claims.')
  jwtClaims: jwtClaims?
}

type jwtClaims = {
  @description('Allowed client applications.')
  allowedClientApplications: string[]?
  @description('Allowed groups.')
  allowedGroups: string[]?
}

type azureStaticWebApp = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The client ID of the app used to login.')
  clientId: string?
}

type facebook = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The App ID of the app used for login.')
  appId: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('The version of the Graph API to use for authentication.')
  graphApiVersion: string?
  @description('Scopes that should be requested while authenticating.')
  scopes: string[]?
}

type gitHub = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The client ID of the app used for login.')
  clientId: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('Scopes that should be requested while authenticating.')
  scopes: string[]?
}

type google = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The client ID of the app used for login.')
  clientId: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('Scopes that should be requested while authenticating.')
  scopes: string[]?
  @description('Allowed list audiences from which to validate the JWT token.')
  allowedAudiences: string[]?
}

type twitter = {
  @description('Enables the identity provider. Default value: **false**.')
  enabled: bool?
  @description('The OAuth 1.0a consumer key of the Twitter/X application used for sign-in.')
  apiKey: string?
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
}

type customOpenIdProvider = {
  @description('The name of the custom OpenID provider.')
  name: string
  @description('The client ID of the app used for login.')
  clientId: string
  @description('The name of the secret from the JSON contained in resourceGroups.containerApps.secrets.secretName.')
  secretName: string?
  @description('''The configuration document URL from your OpenID Connect provider.
    It'll have a suffix with this format: '/.well-known/openid-configuration'.''')
  metadataUri: string?
  @description('The issuer URL for your OpenID Connect provider. This could be a global HTTPS URL for your provider, or one specific to your tenant.')
  issuerUri: string?
  @description('The OAuth 2.0 authorization endpoint from your OpenID Connect provider. Required when issuerUri is configured.')
  authorizationEndpoint: string?
  @description('The OAuth 2.0 token endpoint from your OpenID Connect provider. Required when issuerUri is configured.')
  tokenEndpoint: string?
  @description('''The URL of the authorization server's JSON Web Key Set document. Required when issuerUri is configured.''')
  certificationUri: string?
}

type resourceReferenceNoSub = {
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
}

type resourceReference = {
  @description('The subscription ID of existing resource. Default value: **current subscription** of the deployment.')
  subscriptionId: string?
  @description('The name of the resource group for the existing resource.')
  resourceGroup: string
  @description('The name of the existing resource.')
  name: string
}

@export()
type deploymentLocationType = string

@export()
type tagsType = {
  @description('The value of the tag.')
  *: string
}

@export()
type solutionVersionTagType = {
  *: string
}

targetScope = 'subscription'

@description('Resource Groups to deploy resources to.')
param resourceGroups resourceGroup[]

@description('''Display name of a valid Azure region where the deployment will occur.
  This region is only for the deployment not the resources.
  Will be deprecated in the future and it is not required for Bicep Parameters files.''')
param deploymentLocation deploymentLocationType = deployment().location

@description('Tags to be applied. The tags applied on current level are inherited on everything down below.')
param tags tagsType = {}

@description('''Tag name and value pair that will provide the version for of the solution deployed.
  This is set by lz-deployment-script and it should not be used in Bicep Parameter files. It will be deprecated in the future.''')
param solutionVersionTag solutionVersionTagType = {}
