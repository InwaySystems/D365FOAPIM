var AddCrossCompanyParameterFragment = {
  name: 'AddCrossCompanyParameter'
  value: loadTextContent('apim-policy-fragments/AddCrossCompanyParameter.xml')
  description: 'Adds the cross-company=true parameter to all requests.'
}
var RetryOn429StatusCodeFragment = {
  name: 'RetryOn429StatusCode'
  value: loadTextContent('apim-policy-fragments/RetryOn429StatusCode.xml')
  description: 'On status code 429 (Too Many Requests), retries the request 3 times with a delay of 10 seconds.'
}
var SetEnvironmentVariableFragment = {
  name: 'SetEnvironmentVariable'
  value: loadTextContent('apim-policy-fragments/SetEnvironmentVariable.xml')
  description: 'Sets the variable "environment". The value is either taken from the "Environment" request header or from the DefaultD365FOEnvironment named value.'
}
var SetMicrosoftOAuthorizationHeaderCachedFragment = {
  name: 'SetMicrosoftOAuthorizationHeaderCached'
  value: loadTextContent('apim-policy-fragments/SetMicrosoftOAuthorizationHeaderCached.xml')
  description: 'Gets an OAuth token to authorize requests to the D365FO environment. The token is requested based on the D365FOClientId, D365FOClientSecret and TenantId named values. The token is cached for 20 minutes.'
}
var SetServiceBackendBasedOnEnvironmentVariableFragment = {
  name: 'SetServiceBackendBasedOnEnvironmentVariable'
  value: loadTextContent('apim-policy-fragments/SetServiceBackendBasedOnEnvironmentVariable.xml')
  description: 'Sets the backend service based on the "environment" variable. The variable is set by the SetEnvironmentVariableFragment.'
}
var LogHeadersFragment = {
  name: 'LogHeaders'
  value: loadTextContent('apim-policy-fragments/LogHeaders.xml')
  description: 'Logs all incoming request headers for debugging purposes.'
}


@export()
var fragments = [
  AddCrossCompanyParameterFragment
  RetryOn429StatusCodeFragment
  SetEnvironmentVariableFragment
  SetMicrosoftOAuthorizationHeaderCachedFragment
  SetServiceBackendBasedOnEnvironmentVariableFragment
  LogHeadersFragment
]
