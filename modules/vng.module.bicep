param vngname string = 'vng'
param vngVnetId string
param vngASN int
param tags object
param location string = resourceGroup().location


resource vngpip 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for i in range (1,2): {
  name: '${vngname}-pip-${i}'
  tags: tags
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
  }
}]

resource vng 'Microsoft.Network/virtualNetworkGateways@2021-02-01'= {
  name: vngname
  location: location
  properties:{
    ipConfigurations: [
      {
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: vngVnetId
          }
        publicIPAddress: {
          id: vngpip[0].id
          }
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vngVnetId
            }
          publicIPAddress: {
            id: vngpip[1].id
            }
          }
        }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: true
    bgpSettings:{
      asn: vngASN
    }
    enablePrivateIpAddress: false
    activeActive: true
    gatewayDefaultSite: null
    sku:{
      name: 'VpnGw1AZ'
      tier: 'VpnGw1AZ'
    }
  }
}

output vngPipArray array = [for i in range (0,1) : {
  vngPip: vngpip[i].properties.ipAddress
}]
