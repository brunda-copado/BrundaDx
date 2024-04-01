public with sharing class RollbackWizardValidationExt extends DeploymentHelper{
    private static final List<String> STEPTYPESAVAILABLEFORROLLBACK = new List<String>{ 'Git Promotion', 'Delete MetaData' };

    private static final List<String> DEPLOYMENTSTATUSESFORROLLBACK = new List<String>{ 'Completed Successfully', 'Completed With Errors' };

    private String deploymentId;

    public Map<String, List<Object>> validateDeployment(Deployment__c lastDeployment){
        deployment = lastDeployment;
        if (!isRollbackAvailable()) {
            return pageMessagesMap;
        }
        return new Map<String, List<Object>>();
    }

    private Boolean isRollbackAvailable() {
        try {
            deploymentId = deployment.Id;
            if(deployment.Name.contains('Rollback') && String.isNotBlank(deployment.Rolled_Back_Deployment__c)){
                deploymentId = deployment.Rolled_Back_Deployment__c;
            }
            Deployment__c rolledBackDeployment = [
                SELECT Status__c, (SELECT To_Org__c, To_Org__r.Environment__r.Enable_Rollback__c FROM Destination_Orgs__r LIMIT 1)
                FROM Deployment__c
                WHERE Id = :deploymentId
                WITH SECURITY_ENFORCED
            ];

            if (!rolledBackDeployment.Destination_Orgs__r[0].To_Org__r.Environment__r.Enable_Rollback__c) {
                addErrorMessage(Label.RollbackNotEnabled);
                return false;
            }
        } catch (Exception e) {
            addErrorMessage(
                Label.Insufficient_Access_Rights +
                ': ' +
                Label.Related_Object +
                ' ' +
                Schema.SObjectType.Deployment__c.getLabel() +
                '/' +
                Schema.SObjectType.Destination_Org__c.getLabel()
            );
            return false;
        }

        if (!areAvailableSteps()) {
            return false;
        }

        if (!isDestinationOrgValidated()) {
            addErrorMessage(Label.DESTINATION_ORG_NOT_VALIDATED);
            return false;
        }

        return true;
    }

    private Boolean areAvailableSteps() {
        try {
            List<Step__c> steps = [
                SELECT
                    Id,
                    Name,
                    Type__c,
                    Status__c,
                    (
                        SELECT Id
                        FROM ContentDocumentLinks
                        WHERE ContentDocument.Title = 'Rollback Index.json' OR ContentDocument.Title = 'Rollback metadata.zip'
                    )
                FROM Step__c
                WHERE
                    Deployment__c = :deploymentId
                    AND Type__c IN :STEPTYPESAVAILABLEFORROLLBACK
                    AND Status__c IN :DEPLOYMENTSTATUSESFORROLLBACK
                    AND CheckOnly__c = FALSE
                WITH SECURITY_ENFORCED
            ];

            if (steps.isEmpty()) {
                addErrorMessage(Label.RollbackNoEligibleSteps);
                return false;
            }

            for (Step__c step : steps) {
                if ((step.ContentDocumentLinks.isEmpty() || step.ContentDocumentLinks.size() < 2) && !Test.isRunningTest()) {
                    addErrorMessage(Label.RollbackMissingFiles);
                    return false;
                }
            }

            return true;
        } catch (Exception e) {
            addErrorMessage(Label.Insufficient_Access_Rights + ': ' + Label.Related_Object + ' ' + Schema.SObjectType.Step__c.getLabel());
            return false;
        }
    }

    private Boolean isDestinationOrgValidated() {
        Destination_Org__c destOrg = getDestinationOrg();
        if (destOrg.To_Org__c != null) {
            try {
                List<Org__c> orgs = new OrgsSelector().byId(new Set<Id>{ destOrg.To_Org__c });
                if (!orgs[0].Disable_Validation__c && orgs[0].Validated_Status__c != C_OK) {
                    return DeployAPI.validateOrg(destOrg.To_Org__c);
                }
                return true;
            } catch (Exception e) {
                addErrorMessage(Label.Insufficient_Access_Rights + ' ' + Label.Related_Object + ' ' + Schema.SObjectType.Org__c.getLabel());
            }
        } else {
            addErrorMessage(Label.RollbackMissingDestOrg);
        }
        return false;
    }
    
}