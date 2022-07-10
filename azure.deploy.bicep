targetScope = 'subscription'
param location string
param applicationName string
param environment string
param tags object = {}
param adminUser string 
@secure()
param adminPassword string
param hubCsrPrivateIp string = '192.168.0.4'

var defaultTags = union({
  applicationName: applicationName
  environment: environment
}, tags)
var rgprefix = 'rg-${applicationName}-${environment}'

// create resource groups
resource hubrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${rgprefix}-hub'
  location: location
  tags: defaultTags
}

resource onpremrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${rgprefix}-onprem'
  location: location
  tags: defaultTags
}

resource spokerg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${rgprefix}-spoke'
  location: location
  tags: defaultTags
}

resource branchrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${rgprefix}-branch'
  location: location
  tags: defaultTags
}

// Naming module to configure the naming conventions for Azure
module naming 'modules/naming.module.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'namingDeployment'  
  params: {
    suffix: [
      applicationName
      environment
    ]
    uniqueLength: 6
    uniqueSeed: hubrg.id
  }
}

// Create a diagnostics Storage Account
module diagsa 'modules/sa.module.bicep' = {
  scope: resourceGroup(hubrg.name)
  name:  'diagsadeployment'
  params: {
    tags: defaultTags
    location: location
    naming: naming.outputs.names
  } 
} 

// Hub module to deploy all of its resources such as VNG  
module hub 'hub.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'hubDeployment'
  params: {
    naming: naming.outputs.names
    tags: defaultTags
    location: location
    adminUser: adminUser
    adminPassword: adminPassword
    csrPrivateIP: hubCsrPrivateIp
    diagSaBlobUri: diagsa.outputs.saBlobUri
  }
}

// onprem module
module onprem 'onprem.bicep' = {
  scope: resourceGroup(onpremrg.name)
  name: 'onpremDeployment'
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
    diagSaBlobUri: diagsa.outputs.saBlobUri
    adminPassword: adminPassword
    adminUser: adminUser
  }
}

// spoke module
module spoke 'spoke.bicep' = {
  scope: resourceGroup(spokerg.name)
  name: 'spokeDeployment'
  params: {
    location: location
    adminPassword: adminPassword
    adminUser: adminUser
    naming: naming.outputs.names
    hubCsrPrivateIp: hubCsrPrivateIp
    tags: defaultTags
    diagSaBlobUri: diagsa.outputs.saBlobUri
  }
}

// vnet peering Hub to Spoke
module hubspokepeer 'modules/vnet.peering.module.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'hubspokepeerdeployment'
  params: {
    localVnetId: hub.outputs.hubVnetId
    remoteVnetId: spoke.outputs.spokeVnetId
    allowGatewayTransit: true
  }
}

// vnet peering Hub to Spoke
module spokehubpeer 'modules/vnet.peering.module.bicep' = {
  scope: resourceGroup(spokerg.name)
  name: 'spokehubpeerdeployment'
  params: {
    localVnetId: spoke.outputs.spokeVnetId
    remoteVnetId: hub.outputs.hubVnetId
    useRemoteGateways: true
  }
}

// // branch module 
// module branch 'branch.bicep' = {
//   scope: resourceGroup(branchrg.name)
//   name: 'branchdeployment'
//   params: {
//     location: location
//     adminPassword: adminPassword
//     adminUser: adminUser
//     diagSaBlobUri: diagsa.outputs.saBlobUri
//     naming: naming.outputs.names
//     tags: tags
//   }
// }
