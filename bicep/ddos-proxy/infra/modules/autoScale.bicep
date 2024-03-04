param vmssResourceId string
param appGatewayResourceId string
param autoscaleName string = 'app-gwy-autoscale-requests-per-minute-per-healthy-backend-host'

resource appGatewayScaleSettings 'docum' = {
  name: autoscaleName
  location: resourceGroup().location
  properties: {
    name: autoscaleName
    targetResourceUri: vmssResourceId
    enabled: true
    profiles: [
      {
        name: autoscaleName
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
            metricTrigger: {
              metricName: 'AvgRequestCountPerHealthyHost'
              metricNamespace: 'microsoft.network/applicationgateways'
              metricResourceUri: appGatewayResourceId
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 500
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT1M'
              dimensions: [
                {
                  DimensionName: 'BackendSettingsPool'
                  Operator: 'Equals'
                  Values: [
                    'backendPool~backendHttpsSettings'
                  ]
                }
              ]
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
            metricTrigger: {
              metricName: 'AvgRequestCountPerHealthyHost'
              metricNamespace: 'microsoft.network/applicationgateways'
              metricResourceUri: appGatewayResourceId
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 350
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT1M'
              dimensions: []
              dividePerInstance: false
            }
          }
        ]
      }
    ]
  }
}
