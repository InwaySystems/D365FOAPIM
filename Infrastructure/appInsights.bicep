// Defines an application insights resource.

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string = resourceGroup().location

@description('Specifies the name of the Applications Insights resource.')
param applicationInsightsName string = 'appInsigths${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the Log Analytics Workspace resource.')
param logAnalyticsWorkspaceName string = 'logAnalytics${uniqueString(resourceGroup().id)}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' // Pay-as-you-go pricing
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }  
}

output applicationInsightsName string = appInsights.name
@secure()
output applicationInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
