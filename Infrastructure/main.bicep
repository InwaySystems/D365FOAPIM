@description('''
Id (guid) of the tenant of the D365FO environment.
You can find the tenant id in the about form of the D365FO environment in the licenses section under the name "Serial number".
By default, the tenant id of the Azure Directory where this template is deployed will be used.
''')
param tenantId string = tenant().tenantId

@description('''
URL of the D365FO environment.
''')
param d365FOEnvironmentUrl string = 'https://d365fo-environment-url.dynamics.com'

@description('''
Id (guid) of app registration client for OAuth2.0 authentication with D365FO environment. 
See https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/data-entities/services-home-page#authentication for more details.
Will be stored as a named value in API Management.
''')
param clientId string = '00000000-0000-0000-0000-000000000000'

@description('''
Client secret for OAuth2.0 authentication with D365FO environment. 
See https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/data-entities/services-home-page#authentication for more details.
Will be stored as a secret named value in API Management.
''')
@secure()
param clientSecret string

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

// Add named values for D365FO environment URL, client ID, client secret and tenant
resource d365FOUrlNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: 'DefaultD365FOEnvironment'
  properties: {
    displayName: 'DefaultD365FOEnvironment'
    value: d365FOEnvironmentUrl
  }
}

resource clientIdNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: 'D365FOClientId'
  properties: {
    displayName: 'D365FOClientId'
    value: clientId
  }
}

resource clientSecretNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: 'D365FOClientSecret'
  properties: {
    displayName: 'D365FOClientSecret'
    secret: true
    value: clientSecret
  }
}

resource tenantNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apiManagement
  name: 'TenantId'
  properties: {
    displayName: 'TenantId'
    value: tenantId
  }
}

// Add policy fragments
import * as policyFragmentsStore from 'apim-policy-fragments.bicep'
var policyFragments = policyFragmentsStore.fragments
resource policyFragmentsResources 'Microsoft.ApiManagement/service/policyFragments@2024-05-01' = [
  for fragment in policyFragments: {
    parent: apiManagement
    name: fragment.name
    properties: {
      value: fragment.value
      description: fragment.description
    }
    dependsOn: [
      d365FOUrlNamedValue
      clientIdNamedValue
      clientSecretNamedValue
      tenantNamedValue
    ]
  }
]

// Add API for D365FO
resource d365foApi 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apiManagement
  name: 'D365FOAPI'
  properties: {
    displayName: 'D365FO API'
    format: 'openapi'
    value: loadTextContent('D365FO.openapi.yaml')
    path: '/d365fo'
    protocols: [
      'https'
    ]
  }
}

resource d365foApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: d365foApi
  name: 'policy'
  properties: {
    value: loadTextContent('D365FOAPIPolicy.xml')
  }
  dependsOn: [
    policyFragmentsResources
  ]
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

var logSettings = {
  request: {
    body: {
      bytes: 8192
    }
  }
  response: {
    body: {
      bytes: 8192
    }
  }
}
resource d365foApiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2024-05-01' = {
  parent: d365foApi
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: logSettings
    backend: logSettings
  }
}
