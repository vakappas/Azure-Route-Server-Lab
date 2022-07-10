param location string = resourceGroup().location
param nsgName string 
param nsgDiagLawsId string = ''
param nsgSecurityRules array

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: nsgSecurityRules
  }
}

resource nsgDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(nsgDiagLawsId)) {
  scope: nsg
  name: '${nsg.name}-diag'
  properties: {
    workspaceId: nsgDiagLawsId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

output nsgId string = nsg.id
