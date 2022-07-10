param location string = resourceGroup().location
param bastionHostName string
param bastionHostSubnetId string
param tags object = {
  
}


resource bastionHostPip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${bastionHostName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01'= {
  name: bastionHostName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: '${bastionHostName}-ipconfig'
        properties: {
          subnet: {
            id: bastionHostSubnetId
          }
          publicIPAddress: {
            id: bastionHostPip.id
          }
        }
      }
    ]
  }
}
