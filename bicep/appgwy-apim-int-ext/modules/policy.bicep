targetScope = 'subscription'

param policyAssignmentName string = 'enable-nsg-floe-logs'
param policyDefinitionID string = '/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d'

resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
    name: policyAssignmentName
    scope: subscription()
    properties: {
        policyDefinitionId: policyDefinitionID
    }
}

output assignmentId string = assignment.id
