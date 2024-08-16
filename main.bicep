targetScope = 'subscription'

import * as inputSchema from 'input-types.bicep'
import * as outputSchema from 'output-types.bicep'

@description('Resource Groups to deploy resources to.')
param resourceGroups inputSchema.resourceGroup[]

@description('''Display name of a valid Azure region where the deployment will occur.
  This region is only for the deployment not the resources.
  Will be deprecated in the future and it is not required for Bicep Parameters files.''')
param deploymentLocation inputSchema.deploymentLocationType = deployment().location

@description('Tags to be applied. The tags applied on current level are inherited on everything down below.')
param tags inputSchema.tagsType = {}

@description('''Tag name and value pair that will provide the version for of the solution deployed.
  This is set by lz-deployment-script and it should not be used in Bicep Parameter files. It will be deprecated in the future.''')
param solutionVersionTag inputSchema.solutionVersionTagType= {}

var allTags = union(tags, solutionVersionTag)
var defaultResourceGroup = {
  create: true
  tags: {}
  managedEnvironments: []
  containerApps: []
}

resource resourceGroupsRes 'Microsoft.Resources/resourceGroups@2024-03-01' = [for resourceGroup in resourceGroups: if (union(defaultResourceGroup, resourceGroup).create) {
  name: resourceGroup.name
  location: resourceGroup.location
  tags: union(allTags, union(defaultResourceGroup, resourceGroup).tags)
  properties: {}
}]

module managedEnvironments 'modules/managed-environments.bicep' = [for (resourceGroup, i) in resourceGroups: if (!empty(union(defaultResourceGroup, resourceGroup).managedEnvironments)) {
  name: 'managedEnvironments-${uniqueString(deploymentLocation)}-${i}'
  scope: resourceGroupsRes[i]
  params: {
    managedEnvironments: union(defaultResourceGroup, resourceGroup).managedEnvironments
    tags: union(allTags, union(defaultResourceGroup, resourceGroup).tags)
  }
}]

module containerApps 'modules/container-apps.bicep' = [for (resourceGroup, i) in resourceGroups: if (!empty(union(defaultResourceGroup, resourceGroup).containerApps)) {
  name: 'containerApps-${uniqueString(deploymentLocation)}-${i}'
  scope: resourceGroupsRes[i]
  dependsOn: [
    managedEnvironments
  ]
  params: {
    containerApps: union(defaultResourceGroup, resourceGroup).containerApps
    tags: union(allTags, union(defaultResourceGroup, resourceGroup).tags)
  }
}]

@description('Resource groups deployed by the solution.')
output resourceGroups outputSchema.resourceGroup[] = [for (resourceGroup, i) in resourceGroups: {
  name: resourceGroup.name
  managedEnvironments: !empty(union(defaultResourceGroup, resourceGroup).managedEnvironments) ? managedEnvironments[i].outputs.managedEnvironments : []
  containerApps: !empty(union(defaultResourceGroup, resourceGroup).containerApps) ? containerApps[i].outputs.containerApps : []
}]
