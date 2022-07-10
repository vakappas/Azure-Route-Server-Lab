param localVnetId string
param remoteVnetId string
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

var localVnetName = substring(localVnetId,lastIndexOf(localVnetId,'/')+1, length(localVnetId)-(lastIndexOf(localVnetId,'/')+1))
var remoteVnetName = substring(remoteVnetId,lastIndexOf(remoteVnetId,'/')+1, length(remoteVnetId)-(lastIndexOf(remoteVnetId,'/')+1))

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${localVnetName}/peering-to-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
