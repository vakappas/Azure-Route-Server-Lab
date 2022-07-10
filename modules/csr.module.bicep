param csrVmSize string 
param csrName string
param adminUser string
@secure()
param adminPassword string
param location string
param subnetId string
param diagSaBlobUri string
param tags object = {}
param csrPrivateIP string
param csrPublicIP bool


resource csrPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (csrPublicIP){
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

resource csrNic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${csrName}-nic'
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
            id: subnetId
          }
          publicIPAddress: {
            id: csrPip.id
          }
          privateIPAddress: csrPrivateIP         
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
          id: csrNic.id
        }
      ]
    }
  }
}

output csrPublicIp string = csrPip.properties.ipAddress
