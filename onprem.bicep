param naming object
param tags object
param location string = resourceGroup().location
param adminUser string
@secure()
param adminPassword string
param diagSaBlobUri string

var resourceNames = {
  vnet: replace(naming.virtualNetwork.name, 'vnet-', 'vnet-onprem-')
  subnet: naming.subnet.name
  laws: replace(naming.logAnalyticsWorkspace.name, 'log-', 'log-onprem-')
  bastionnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-bastion-onprem-')
  csrnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-csr-onprem-')
  vmnsg: replace(naming.networkSecurityGroup.name, 'nsg-', 'nsg-vm-onprem-')
  bastionhost: replace(naming.bastionHost.name, 'snap-', 'bastion-onprem-')
  onpremrt: replace(naming.routeTable.name, 'route-', 'rt-onprem-')
  csr: 'csr-onprem'
  csrprivateip: '192.168.16.4'
}

// Log Analytics Workspace
module laws 'modules/laws.module.bicep' = {
  name: 'onpremlawsDeployment'
  params: {
    location: location
    lawsName: resourceNames.laws
    tags: tags
  }
}
// Create the onprem vnet
module vnet './modules/vnet.module.bicep' = {
  name: 'onpremvnetDeployment'
  params: {
    location: location
    tags: tags
    vnetName: resourceNames.vnet
    vnetPrefix: '192.168.16.0/24'
    vnetDiagLawsId: laws.outputs.lawsId
    subnets: [
      {
        name: replace(resourceNames.subnet, 'snet-','snet-nva-')
        subnetPrefix: '192.168.16.0/26'
        privateEndpointNetworkPolicies: 'Disabled'
        nsgid: csrnsg.outputs.nsgId
      }
      {
        name: replace(resourceNames.subnet, 'snet-','snet-mgmt-')
        subnetPrefix: '192.168.16.64/26'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: vmnsg.outputs.nsgId
        routeTableid: onpremrt.outputs.routeTableid
      }
      {
        name: 'AzureBastionSubnet'
        subnetPrefix: '192.168.16.128/27'
        privateEndpointNetworkPolicies: 'Enabled'
        nsgid: bastionsg.outputs.nsgId
      }
    ]
  }
}

// Create the required NSGs
module bastionsg 'modules/nsg.module.bicep' = {
  name: 'onprembastionnsgDeployment'
  params: {
    location: location
    nsgName: resourceNames.bastionnsg
    nsgDiagLawsId: laws.outputs.lawsId
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
  name: 'onpremcsrnsgdeployment'
  params: {
    location: location
    nsgName: resourceNames.csrnsg
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
module vmnsg 'modules/nsg.module.bicep' = {
  name: 'onpremvmnsgdeployment'
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
// Create the Azure Bastion 
module bastion 'modules/bastion.module.bicep' = {
  name: 'onprembastionDeployment'
  params: {
    location: location
    tags: tags
    bastionHostName: resourceNames.bastionhost
    bastionHostSubnetId: vnet.outputs.subnet[2].subnetID
  }
}
// Create the required UDR
module onpremrt 'modules/routetable.module.bicep' = {
  name: 'onpremrtdeployment'
  params: {
    location: location
    addressPrefix: '192.168.0.0/19'
    udrName: resourceNames.onpremrt
    udrRouteName: 'internal-vnets'
    nextHopIpAddress: resourceNames.csrprivateip
    nextHopType: 'VirtualAppliance'
  }
}
// Create the CSRs
module csr 'modules/csr.module.bicep' = {
  name: 'onpremcsrdeployment'
  params: {
    tags: tags
    adminPassword: adminPassword
    adminUser: adminUser
    csrVmSize: 'Standard_DS2_v2'
    csrName: resourceNames.csr
    csrPublicIP: true
    csrPrivateIP: resourceNames.csrprivateip
    diagSaBlobUri: diagSaBlobUri
    location: location
    subnetId: vnet.outputs.subnet[0].subnetID
  }
}

// Create a test Ubuntu VM
module mgmtvm 'modules/vm.linux.module.bicep' = {
  name: 'onpremmgmtvmdeployment'
  params: {
    location: location
    vmSize: 'Standard_B2ms'
    vmName: 'onpvm01'
    adminPasswordOrKey: adminPassword
    adminUser: adminUser
    diagSaBlobUri: diagSaBlobUri
    subnetID: vnet.outputs.subnet[1].subnetID
    authenticationType: 'password'
  }
}

// Cretae the Local Network Gateway
module lng 'modules/lng.modules.bicep' = {
  name: 'lngdeployment'
  params: {
    location: location
    tags: tags
    bgpPeeringAddress: resourceNames.csrprivateip
    lngAsn: 65501
    lngName: 'lng-onprem'
    gwPip: csr.outputs.csrPublicIp
  }
}


output onpremVnetId string = vnet.outputs.vnetID




