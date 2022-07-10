param lngName string
param location string = resourceGroup().location
param tags object
param lngAsn int
param gwPip string
param bgpPeeringAddress string

resource lng 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: lngName
  location: location
  tags: tags
  properties: {
    bgpSettings: {
      asn: lngAsn
      bgpPeeringAddress: bgpPeeringAddress
      peerWeight: 0
    }

    gatewayIpAddress: gwPip
    localNetworkAddressSpace: {
      addressPrefixes: [
        '${bgpPeeringAddress}/32'
      ]
    }
  }
}
