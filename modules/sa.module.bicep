param location string
param tags object = {}
param naming object

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: naming.storageAccount.nameUnique
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  resource blob 'blobServices@2021-04-01' = {
    name: 'default'
  }
}

output saBlobUri string = sa.properties.primaryEndpoints.blob
