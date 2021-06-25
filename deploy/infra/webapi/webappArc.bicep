param location string
param workspaceId string
param appSettingsPgHost string
param appSettingsPgUser string
@secure()
param appSettingsPgPassword string
param appSettingsPgDb string
param appSettingsNodeEnv string
param appSettingsInsightsKey string
param webApiHostingPlanName string
param webApiName string
param kubeEnvironmentId string
param customLocationId string

resource webApiHostingPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: webApiHostingPlanName
  location: location
  kind: 'linux,kubernetes'
  sku: {
    name: 'K1'
    tier: 'Kubernetes'
    capacity: 1 // not required
  }
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    reserved: true
    perSiteScaling: true
    isXenon: false
    kubeEnvironmentProfile: {
      id: kubeEnvironmentId
    }
  }
}

resource webApi 'Microsoft.Web/sites@2021-01-01' = {
  name: webApiName
  location: location
  kind: 'linux,kubernetes,app'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    serverFarmId: webApiHostingPlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|14-lts'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'PGHOST'
          value: appSettingsPgHost
        }
        {
          name: 'PGUSER'
          value: appSettingsPgUser
        }
        {
          name: 'PGPASSWORD'
          value: appSettingsPgPassword
        }
        {
          name: 'PGDB'
          value: appSettingsPgDb
        }
        {
          name: 'NODE_ENV'
          value: appSettingsNodeEnv
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appSettingsInsightsKey
        }
        {
          name: 'PGSSLMODE'
          value: 'allow'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'CUSTOM_BUILD_COMMAND'
          value: 'npm ci --production'
        }
      ]
    }
  }
}

resource webDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: webApi
  name: 'logAnalytics-${webApiName}'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        enabled: true
        category: 'AppServicePlatformLogs'
      }
      {
        enabled: true
        category: 'AppServiceIPSecAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceFileAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAppLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
      }
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceAntivirusScanAuditLogs'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output webApiId string = webApi.id
