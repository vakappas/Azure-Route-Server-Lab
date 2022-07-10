param naming object
param tags object
param location string = resourceGroup().location
param adminUser string
@secure()
param adminPassword string
param diagSaBlobUri string
param hubCsrPrivateIp string

var resourceNames = {
  vnet: replace(naming.virtualNetwork.name, 'vnet-', 'vnet-spoke-')
  subnet: naming.subnet.name
  laws: replace(naming.logAnalyticsWorkspace.name, 'log-', 'log-spoke-')
  vmnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-vm-spoke-')
  rt: replace(naming.routeTable.name, 'route-', 'rt-spoke-')
}

// Log Analytics Workspace
module laws 'modules/laws.module.bicep' = {
  name: 'spokelawsDeployment'
  params: {
    location: location
    lawsName: resourceNames.laws
    tags: tags
  }
}
// Create the spoke vnet
module vnet './modules/vnet.module.bicep' = {
  name: 'spokevnetDeployment'
  params: {
    location: location
    tags: tags
    vnetName: resourceNames.vnet
    vnetPrefix: '192.168.1.0/24'
    vnetDiagLawsId: laws.outputs.lawsId
    subnets: [
      {
        name: replace(resourceNames.subnet, 'snet-','snet-web-')
        subnetPrefix: '192.168.1.0/26'
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: replace(resourceNames.subnet, 'snet-','snet-mgmt-')
        subnetPrefix: '192.168.1.64/26'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: vmnsg.outputs.nsgId
        routeTableid: rt.outputs.routeTableid
      }
    ]
  }
}

// Create the required NSGs
module vmnsg 'modules/nsg.module.bicep' = {
  name: 'spokevmnsgdeployment'
  params: {
    location: location
    nsgName: resourceNames.vmnsg
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

// Create the required UDR
module rt 'modules/routetable.module.bicep' = {
  name: 'spokertdeployment'
  params: {
    location: location
    addressPrefix: '0.0.0.0/0'
    udrName: resourceNames.rt
    udrRouteName: 'rt-default'
    nextHopIpAddress: hubCsrPrivateIp
    nextHopType: 'VirtualAppliance'
  }
}


// Create a test Ubuntu VM
module vm 'modules/vm.linux.module.bicep' = {
  name: 'spokemgmtvmdeployment'
  params: {
    location: location
    vmSize: 'Standard_B2ms'
    vmName: 'sp1vm01'
    adminPasswordOrKey: adminPassword
    diagSaBlobUri: diagSaBlobUri
    adminUser: adminUser
    subnetID: vnet.outputs.subnet[1].subnetID
    authenticationType: 'password'
  }
}



output spokeVnetId string = vnet.outputs.vnetID




