@export()
type resourceGroup = {
  @description('The name of the resource group.')
  name: string
  @description('Container Apps environments deployed.')
  managedEnvironments: managedEnvironment[]
  @description('Container Apps deployed.')
  containerApps: containerApp[]
}

type managedEnvironment = {
  @description('The name of the Container App environment.')
  name: string
  @description('''The environment's external static IP address. Used for ingress traffic of configured container apps.''')
  ipAddress: string?
  @description('''The default domain name to access container apps' ingress.''')
  defaultDomainName: string?
}

type containerApp = {
  @description('The name of Container App.')
  name: string
  @description('The system identity configured on the resource.')
  identity: identity?
  @description('IP addresses used for outbound traffic.')
  outboundIpAddresses: string[]?
  @description('''The verification string to use for verifying custom domains. Needs to be configured as a TXT record for asuid.\<customDomainName\>.''')
  customDomainVerificationId: string?
}

type identity = {
  @description('The type of identity configured on the resource.')
  type: 'SystemAssigned' | 'SystemAssigned, UserAssigned' | 'UserAssigned' | 'None' | ''
  @description('The principal ID of the system assigned identity.')
  principalId: string
  @description('The tenant ID of the identity.')
  tenantId: string
}
