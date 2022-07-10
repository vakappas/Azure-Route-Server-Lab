param location string = resourceGroup().location
param lawsName string
param tags object 

resource lawsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: lawsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output lawsId string = lawsWorkspace.id
