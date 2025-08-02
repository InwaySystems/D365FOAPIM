
resource apiManagement 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: 'D365FOAPIManagement-${take(uniqueString(tenant().tenantId, resourceGroup().id), 5)}'
  location: resourceGroup().location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: deployer().userPrincipalName
    publisherName: tenant().displayName
  }
}
