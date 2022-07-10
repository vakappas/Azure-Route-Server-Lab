param csrVmSize string 
param csrName string
param adminUser string
@secure()
param adminPassword string
param location string
param inSubnetId string
param outSubnetId string
param diagSaBlobUri string
param tags object = {}
param csrPrivateIP string



resource csrPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${csrName}-pip'
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

resource inNic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${csrName}-nic-inside'
  location: location
  tags: tags
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: inSubnetId
          }
          privateIPAddress: csrPrivateIP         
        }
      }
    ]
  }
}

resource outNic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${csrName}-nic-outside'
  location: location
  tags: tags
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: outSubnetId
          }
          publicIPAddress: {
            id: csrPip.id
          }
        }
      }
    ]
  }
}

resource csr 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: csrName
  location: location
  tags: tags
  plan:{
    name: '16_12_5-byol'
    publisher: 'cisco'
    product: 'cisco-csr-1000v'
  }
  properties: {
    hardwareProfile:{
      vmSize: csrVmSize
    }
    storageProfile:  {
      imageReference: {
        publisher: 'cisco'
        offer: 'cisco-csr-1000v'
        sku: '16_12_5-byol'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'      
        }
      }
      osProfile:{
        computerName: csrName
        adminUsername: adminUser
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            patchMode: 'ImageDefault'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: diagSaBlobUri
        }
      }
      networkProfile: {
        networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: inNic.id
        }
        {
          properties: {
            primary: false
          }
          id: outNic.id
        }
      ]
    }
  }
}

output csrPublicIp string = csrPip.properties.ipAddress
