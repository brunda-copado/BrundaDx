public with sharing class RollbackWizardStartExt extends DeploymentHelper {
    private List<String> stepTypesAvailableForRollback = new List<String>{ 'Git Promotion', 'Delete MetaData' };

    public RollbackWizardStartExt(ApexPages.StandardController stdCtrl) {
        if (!Test.isRunningTest()) {
            stdCtrl.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
        }
        Deployment__c rollbackDeployment = (Deployment__c) stdCtrl.getRecord();
        deployment = rollbackDeployment;
        initializeServiceClasses();
        populateNecessaryData();
        populateStepsList();
        populatePagesList();
    }

    // PUBLIC

    public PageReference saveAndGoToNextStep() {
        upsertDeployment(true, true);
        PageReference pageRef = pageMessagesMap.isEmpty() ? goToNextStep() : null;
        return pageRef;
    }

    // PRIVATE

    private void populateNecessaryData() {
        pageMessagesMap.clear();
        sourceList = new List<SourceWrapper>();

        RollbackWizardValidationExt validateRollback = new RollbackWizardValidationExt();

        pageMessagesMap = validateRollback.validateDeployment(deployment);
        if(!pageMessagesMap.isEmpty()){
            return;
        }

        try {
            for (Step__c step : [
                SELECT
                    Id,
                    Name,
                    Type__c,
                    Status__c,
                    CheckOnly__c,
                    Order__c,
                    (
                        SELECT Id
                        FROM ContentDocumentLinks
                        WHERE ContentDocument.Title = 'Rollback Index' OR ContentDocument.Title = 'Rollback Index.json'
                    )
                FROM Step__c
                WHERE Deployment__c = :deployment.Rolled_Back_Deployment__c
                WITH SECURITY_ENFORCED
                ORDER BY Order__c ASC
            ]) {
                String reason = getRollbackAvailability(step);
                sourceList.add(new SourceWrapper(step.Name, step.Type__c, step.Status__c, reason == '', reason));
            }
        } catch (Exception e) {
            addErrorMessage(
                Label.Insufficient_Access_Rights +
                ' ' +
                Label.Related_Object +
                ' ' +
                Schema.SObjectType.Step__c.getLabel() +
                '/' +
                Schema.SObjectType.ContentDocumentLink.getLabel()
            );
            return;
        }
    }

    private String getRollbackAvailability(Step__c step) {
        String result = '';

        if (!stepTypesAvailableForRollback.contains(step.Type__c)) {
            result = Label.RollbackStepTypeNotEligible;
        } else if (step.CheckOnly__c) {
            result = Label.RollbackValidationStepMessage;
        } else if (step.ContentDocumentLinks.isEmpty()) {
            result = Label.RollbackMissingFilesMessage;
        }

        return result;
    }
}