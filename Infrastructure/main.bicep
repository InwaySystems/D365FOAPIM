@description('Id of app registration client for OAuth2.0 authentication with D365FO environment. Will be stored as a named value in API Management.')
param namedValueClientId string

// Create base API Management service resource
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

resource clientIdNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: 'D365FOClientId'
  properties: {
    displayName: 'D365FOClientId'
    value: namedValueClientId
  }
}

// Add Application Insights for monitoring
var applicationInsightsName string = 'appInsights${uniqueString(resourceGroup().id)}'
module appInsights 'appInsights.bicep' = {
  name: 'D365FOAPIManagementMonitoring'
  params: {
    applicationInsightsName: applicationInsightsName
  }
}

var appInsightsInstrumentationKeyNamedValueName = 'ApplicationInsightsInstrumentationKey'
resource secretNamedValueAppInsights 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: appInsightsInstrumentationKeyNamedValueName
  properties: {
    displayName: appInsightsInstrumentationKeyNamedValueName
    secret: true
    value: appInsights.outputs.applicationInsightsInstrumentationKey
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2024-05-01' = {
  parent: apiManagement
  name: applicationInsightsName
  properties: {
    loggerType: 'applicationInsights'
    isBuffered: true
    credentials: {
      // refer to named value that contains the Application Insights instrumentation key
      instrumentationKey: '{{${appInsightsInstrumentationKeyNamedValueName}}}'
    }
  }
  dependsOn: [
    secretNamedValueAppInsights
  ]
}
