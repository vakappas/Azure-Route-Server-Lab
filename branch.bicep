param naming object
param tags object
param location string = resourceGroup().location
param adminUser string
@secure()
param adminPassword string
param diagSaBlobUri string 

var resourceNames = {
  vnet: replace(naming.virtualNetwork.name, 'vnet-', 'vnet-branch-')
  subnet: naming.subnet.name
  laws: replace(naming.logAnalyticsWorkspace.name, 'log-', 'log-branch-')
  vmnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-branchvm-')
  vng: replace(naming.virtualNetworkGateway.name, 'vgw-', 'vng-branch-')
}

// Log Analytics Workspace
module laws 'modules/laws.module.bicep' = {
  name: 'branchlawsDeployment'
  params: {
    location: location
    lawsName: resourceNames.laws
    tags: tags
  }
}
// Create the required NSGs

module vmnsg 'modules/nsg.module.bicep' = {
  name: 'branchvmnsgdeployment'
  params: {
    location: location
    nsgName: resourceNames.vmnsg
    nsgDiagLawsId: laws.outputs.lawsId
    nsgSecurityRules: [

      {
        name: 'Allow_Inbound_RFC1918'
        properties: {
          description: 'Allow_Inbound_RFC1918'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefixes: [
            '10.0.0.0/8'
            '172.16.0.0/12'
            '192.168.0.0/16'
          ] 
          destinationPortRange: '*'
          destinationAddressPrefixes: [
            '10.0.0.0/8'
            '172.16.0.0/12'
            '192.168.0.0/16'
          ] 
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Outbound_RFC1918'
        properties: {
          description: 'Allow_Outbound_RFC1918'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefixes: [
            '10.0.0.0/8'
            '172.16.0.0/12'
            '192.168.0.0/16'
          ] 
          destinationPortRange: '*'
          destinationAddressPrefixes: [
            '10.0.0.0/8'
            '172.16.0.0/12'
            '192.168.0.0/16'
          ] 
          access: 'Allow'
          priority: 300
          direction: 'Outbound'
        }
      }
    ]
  }
}
// Create the branch vnet
module vnet './modules/vnet.module.bicep' = {
  name: 'branchvnetDeployment'
  params: {
    location: location
    tags: tags
    vnetName: resourceNames.vnet
    vnetPrefix: '192.168.8.0/24'
    vnetDiagLawsId: laws.outputs.lawsId
    subnets: [
      
      {
        name: 'GatewaySubnet'
        subnetPrefix: '192.168.8.0/27'
        privateEndpointNetworkPolicies: 'Enabled'
      }
      {
        name: replace(resourceNames.subnet, 'snet-','snet-mgmt-')
        subnetPrefix: '192.168.8.128/25'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: vmnsg.outputs.nsgId
      }
      
    ]
  }
}

// Create the Azure VPN Gateway
module vng 'modules/vng.module.bicep' = {
  name: 'branchvngdeployment'
  params: {
    location: location
    tags: tags
    vngname: resourceNames.vng
    vngASN: 65521
    vngVnetId: vnet.outputs.subnet[0].subnetID
  }
}

// Create a test Ubuntu VM
module vm 'modules/vm.linux.module.bicep' = {
  name: 'branchvmdeployment'
  params: {
    location: location
    vmName: 'bravm01'
    vmSize: 'Standard_B2ms'
    diagSaBlobUri: diagSaBlobUri
    adminPasswordOrKey: adminPassword
    adminUser: adminUser
    subnetID: vnet.outputs.subnet[1].subnetID
    authenticationType: 'password'
  }
}

output VnetId string = vnet.outputs.vnetID
output LawsId string = laws.outputs.lawsId
output vngPipArray array = [for i in range (0,1) : {
  vngPip: vng.outputs.vngPipArray[i].vngpip
}]
// hubVngPip1 string = vng.outputs.vngPipArray[0].vngPip
// hubVngPip2 string = vng.outputs.vngPipArray[1].vngPip




