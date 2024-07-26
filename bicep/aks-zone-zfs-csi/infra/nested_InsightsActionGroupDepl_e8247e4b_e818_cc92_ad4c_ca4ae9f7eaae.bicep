param tagsForAllResources object

resource RecommendedAlertRules_AG_1 'microsoft.insights/actionGroups@2022-06-01' = {
  name: 'RecommendedAlertRules-AG-1'
  location: 'Global'
  properties: {
    groupShortName: 'recalert1'
    enabled: true
    emailReceivers: [
      {
        name: 'Email_-EmailAction-'
        emailAddress: 'cbellee@microsoft.com'
        useCommonAlertSchema: true
      }
    ]
    emailSMSAppReceivers: []
  }
  tags: tagsForAllResources
}
