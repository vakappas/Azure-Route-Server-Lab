param naming object
param tags object
param location string = resourceGroup().location
param adminUser string
@secure()
param adminPassword string
param diagSaBlobUri string 
param csrPrivateIP string

var resourceNames = {
  hubvnet: replace(naming.virtualNetwork.name, 'vnet-', 'vnet-hub-')
  subnet: naming.subnet.name
  hublaws: replace(naming.logAnalyticsWorkspace.name, 'log-', 'log-hub-')
  bastionnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-bastion-hub-')
  csrnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-csr-hub-')
  vmnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-hubvm-')
  bastionhost: replace(naming.bastionHost.name, 'snap-', 'bastion-hub-')
  hubvng: replace(naming.virtualNetworkGateway.name, 'vgw-', 'vng-hub-')
  hubcsr: 'csr-hub'
}

// Log Analytics Workspace
module hublaws 'modules/laws.module.bicep' = {
  name: 'hublawsDeployment'
  params: {
    location: location
    lawsName: resourceNames.hublaws
    tags: tags
  }
}
// Create the required NSGs
module bastionsg 'modules/nsg.module.bicep' = {
  name: 'bastionnsgDeployment'
  params: {
    location: location
    nsgName: resourceNames.bastionnsg
    nsgDiagLawsId: hublaws.outputs.lawsId
    nsgSecurityRules: [
        {
          name: 'AllowWebExperienceInBound'
          properties: {
            description: 'Allow our users in. Update this to be as restrictive as possible.'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationPortRange: '443'
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 100
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowControlPlaneInBound'
          properties: {
            description: 'Service Requirement. Allow control plane access. Regional Tag not yet supported.'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'GatewayManager'
            destinationPortRange: '443'
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 110
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowHealthProbesInBound'
          properties: {
            description: 'Service Requirement. Allow Health Probes.'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationPortRange: '443'
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 120
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowBastionHostToHostInBound'
          properties: {
            description: 'Service Requirement. Allow Required Host to Host Communication.'
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: 'VirtualNetwork'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 130
            direction: 'Inbound'
          }
        }
        {
          name: 'DenyAllInBound'
          properties: {
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '*'
            destinationAddressPrefix: '*'
            access: 'Deny'
            priority: 1000
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowSshToVnetOutBound'
          properties: {
            description: 'Allow SSH out to the VNet'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '22'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 100
            direction: 'Outbound'
          }
        }
        {
          name: 'AllowRdpToVnetOutBound'
          properties: {
            protocol: 'Tcp'
            description: 'Allow RDP out to the VNet'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '3389'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 110
            direction: 'Outbound'
          }
        }
        {
          name: 'AllowControlPlaneOutBound'
          properties: {
            description: 'Required for control plane outbound. Regional prefix not yet supported'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '443'
            destinationAddressPrefix: 'AzureCloud'
            access: 'Allow'
            priority: 120
            direction: 'Outbound'
          }
        }
        {
          name: 'AllowBastionHostToHostOutBound'
          properties: {
            description: 'Service Requirement. Allow Required Host to Host Communication.'
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: 'VirtualNetwork'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 130
            direction: 'Outbound'
          }
        }
        {
          name: 'AllowBastionCertificateValidationOutBound'
          properties: {
            description: 'Service Requirement. Allow Required Session and Certificate Validation.'
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '80'
            destinationAddressPrefix: 'Internet'
            access: 'Allow'
            priority: 140
            direction: 'Outbound'
          }
        }
        {
          name: 'DenyAllOutBound'
          properties: {
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationPortRange: '*'
            destinationAddressPrefix: '*'
            access: 'Deny'
            priority: 1000
            direction: 'Outbound'
          }
        }
    ]
  }
}
module csrnsg 'modules/nsg.module.bicep' = {
  name: 'hubcsrnsgdeployment'
  params: {
    location: location
    nsgName: resourceNames.csrnsg
    nsgDiagLawsId: hublaws.outputs.lawsId
    nsgSecurityRules: [
      {
        name: 'Allow_UDP_ports_for_IKE'
          properties: {
            description: 'UDP ports for IKE'
            protocol: 'Udp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationPortRanges: [
              '500'
              '4500'
            ]
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 100
            direction: 'Inbound'
          }
      }
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
module mgmtvmnsg 'modules/nsg.module.bicep' = {
  name: 'hubvmnsgdeployment'
  params: {
    location: location
    nsgName: resourceNames.vmnsg
    nsgDiagLawsId: hublaws.outputs.lawsId
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
// Create the hub vnet
module vnet './modules/vnet.module.bicep' = {
  name: 'hubvnetDeployment'
  params: {
    location: location
    tags: tags
    vnetName: resourceNames.hubvnet
    vnetPrefix: '192.168.0.0/24'
    vnetDiagLawsId: hublaws.outputs.lawsId
    subnets: [
      {
        name: replace(resourceNames.subnet, 'snet-','snet-nva-in')
        subnetPrefix: '192.168.0.0/27'
        privateEndpointNetworkPolicies: 'Disabled'
        nsgid: csrnsg.outputs.nsgId
      }
      {
        name: replace(resourceNames.subnet, 'snet-','snet-nva-out')
        subnetPrefix: '192.168.0.32/27'
        privateEndpointNetworkPolicies: 'Disabled'
        nsgid: csrnsg.outputs.nsgId
      }
      {
        name: replace(resourceNames.subnet, 'snet-','snet-mgmt-')
        subnetPrefix: '192.168.0.64/26'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: mgmtvmnsg.outputs.nsgId
      }
      {
        name: 'RouteServerSubnet'
        subnetPrefix: '192.168.0.160/27'
        privateEndpointNetworkPolicies: 'Enabled'
      }
      {
        name: 'AzureBastionSubnet'
        subnetPrefix: '192.168.0.192/27'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: bastionsg.outputs.nsgId
      }
      {
        name: 'GatewaySubnet'
        subnetPrefix: '192.168.0.224/27'
        privateEndpointNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// Create the Azure Bastion 
module bastion 'modules/bastion.module.bicep' = {
  name: 'hubbastionDeployment'
  params: {
    location: location
    tags: tags
    bastionHostName: resourceNames.bastionhost
    bastionHostSubnetId: vnet.outputs.subnet[4].subnetID
  }
}

// Create the Azure VPN Gateway
module vng 'modules/vng.module.bicep' = {
  name: 'hubvngdeployment'
  params: {
    location: location
    tags: tags
    vngname: resourceNames.hubvng
    vngASN: 65512
    vngVnetId: vnet.outputs.subnet[5].subnetID
  }
}

// Create the CSRs
module csr 'modules/csr.2nics.module.bicep' = {
  name: 'hubcsrdeployment'
  params: {
    tags: tags
    adminPassword: adminPassword
    adminUser: adminUser
    csrName: resourceNames.hubcsr
    csrVmSize: 'Standard_DS2_v2'
    csrPrivateIP: csrPrivateIP
    diagSaBlobUri: diagSaBlobUri
    location: location
    inSubnetId: vnet.outputs.subnet[0].subnetID
    outSubnetId: vnet.outputs.subnet[1].subnetID
  }
}

// Create a test Ubuntu VM
module mgmtvm 'modules/vm.linux.module.bicep' = {
  name: 'mgmtvmdeployment'
  params: {
    location: location
    vmName: 'mgmtvm01'
    vmSize: 'Standard_B2ms'
    adminPasswordOrKey: adminPassword
    adminUser: adminUser
    diagSaBlobUri: diagSaBlobUri
    subnetID: vnet.outputs.subnet[2].subnetID
    authenticationType: 'password'
  }
}

// Create the Route Server
module ars 'modules/routeserver.module.bicep' = {
  name: 'arsdeployment'
  params: {
    location: location
    arsname: 'ars-hub'
    arsVnetId: vnet.outputs.subnet[3].subnetID
    asrPeerAsn: 65510
    asrPeerPrivateIp: csrPrivateIP
    tags: tags    
  }
}

output hubVnetId string = vnet.outputs.vnetID
output hubLawsId string = hublaws.outputs.lawsId
// hubVngPip1 string = vng.outputs.vngPipArray[0].vngPip
// hubVngPip2 string = vng.outputs.vngPipArray[1].vngPip




