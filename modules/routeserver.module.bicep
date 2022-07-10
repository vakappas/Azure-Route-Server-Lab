param arsname string = 'vng'
param arsVnetId string
param asrPeerAsn int
param asrPeerPrivateIp string
param tags object
param location string = resourceGroup().location


resource arspip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${arsname}-pip'
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
}

resource ars 'Microsoft.Network/virtualHubs@2021-05-01' = {
  name: arsname
  tags: tags
  location: location
  properties: {
    sku: 'Standard'
    allowBranchToBranchTraffic: true
  }  
}

resource arsIpConfig 'Microsoft.Network/virtualHubs/ipConfigurations@2021-05-01' = {
  name: '${arsname}/rsIpConfig'
    properties: {
    subnet: {
      id: arsVnetId
    }
    publicIPAddress: {
      id: arspip.id
    }
  }
}

// resource arsBgpConn 'Microsoft.Network/virtualHubs/bgpConnections@2021-05-01' = {
//   parent: ars
//   name: '${arsname}-bgpconn'
//   properties: {
//     peerAsn: asrPeerAsn
//     peerIp: asrPeerPrivateIp
// 
//   }
// }
