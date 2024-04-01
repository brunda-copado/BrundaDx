public with sharing class RollbackWizardExt extends DeploymentHelper {
    //constants
    private final Set<String> deploymentStatusSet;
    private final String INSUFFICIENT_RIGHT_DEPLOYMENT = Label.Insufficient_Access_Rights + ': ' + Label.Related_Object + ' ' + Schema.SObjectType.Deployment__c.getLabel();
    private final String INSUFFICIENT_RIGHT_DESTINATION_ORG = Label.Insufficient_Access_Rights + ': ' + Label.Related_Object + ' ' + Schema.SObjectType.Destination_org__c.getLabel();
    private final String DISALLOW_NON_ADMIN_PROD_ROLLBACK = Label.RollbackLicenseCheck;
    //non-constants
    private Promotion__c promotion;
    private Deployment__c lastDeployment;
    private List<Deployment__c> lastRollbackDeployment;
    private String rollbackDeploymentName;
    private Deployment__c rollbackDeployment;
    private Boolean isEnvTypeProduction = false;
    // CTOR

    public RollbackWizardExt(ApexPages.StandardController stdCtrl) {
        if (!Test.isRunningTest()) {
            stdCtrl.addFields(new List<String>(Schema.SObjectType.Promotion__c.fields.getMap().keySet()));
        }

        promotion = (Promotion__c) stdCtrl.getRecord();

        isEnvTypeProduction = [SELECT Destination_Environment__r.Type__c 
                                FROM Promotion__c 
                                WHERE ID = :promotion.Id AND
                                Destination_Environment__r.Type__c LIKE '%Production%' WITH SECURITY_ENFORCED].isEmpty() ? false : true;

        List<Deployment__c> deployments = [
            SELECT Name, From_Org__c, Status__c, RecordTypeId, (SELECT To_Org__c, To_Org__r.Environment__r.Enable_Rollback__c FROM Destination_Orgs__r LIMIT 1)
            FROM Deployment__c
            WHERE Promotion__c = :promotion.Id
            AND Rolled_Back_Deployment__c = null
            WITH SECURITY_ENFORCED
            ORDER BY lastModifiedDate DESC
            LIMIT 1
        ];
        
        if (!deployments.isEmpty()) {
            lastDeployment = deployments[0];
            deploymentStatusSet = new Set<String> {'Completed with Errors', 'Cancelled', 'Merge Conflict', 'Outdated', 'Completed Successfully'};
        } else {
            addErrorMessage(Label.RollbackNoEligibleSteps);
        }
    }

    private void assignLastRollbackDeployment(){
        RollbackWizardValidationExt validateRollback = new RollbackWizardValidationExt();
        pageMessagesMap = validateRollback.validateDeployment(lastDeployment);
        if(!pageMessagesMap.isEmpty()){
            return;
        }
        rollbackDeploymentName = ('Rollback ' + lastDeployment.Name).length() > 80 ? ('Rollback ' + lastDeployment.Name).subString(0, 80) : ('Rollback ' + lastDeployment.Name);
        try{
            lastRollbackDeployment = [
                SELECT Name, Deployment_Last_Step__c, Status__c
                FROM Deployment__c
                WHERE Name = :rollbackDeploymentName
                AND Promotion__c = :promotion.Id
                WITH SECURITY_ENFORCED
                ORDER BY lastModifiedDate DESC
                LIMIT 1
            ];
        } catch(Exception ex) {
            addErrorMessage(INSUFFICIENT_RIGHT_DEPLOYMENT);
        }
    }

    private void generateRollbackDeployment(){
        rollbackDeployment = new Deployment__c(Name = rollbackDeploymentName, Rolled_Back_Deployment__c = lastDeployment.Id, Promotion__c = promotion.Id);
        try {
            Utilities.Secure_DML(rollbackDeployment, Utilities.DML_Action.INS, schema.SObjectType.Deployment__c);
            Destination_org__c rollbackDestination = new Destination_org__c(
                To_Org__c = lastDeployment.Destination_Orgs__r[0].To_Org__c,
                Deployment__c = rollbackDeployment.Id
            );
            Utilities.Secure_DML(rollbackDestination, Utilities.DML_Action.INS, schema.SObjectType.Destination_org__c);
        } catch(Exception ex) {
            String error = ex.getMessage().contains('Insufficient permissions') ? (ex.getMessage().contains('Destination_org__c') ? INSUFFICIENT_RIGHT_DESTINATION_ORG : INSUFFICIENT_RIGHT_DEPLOYMENT) : ex.getMessage();
            addErrorMessage(error);
        }
    }

    // PUBLIC
    public PageReference redirectToCorrectPage() {

        if (this.isEnvTypeProduction && !LicenseHelper.isCopadoEnabled()) {
            addErrorMessage(DISALLOW_NON_ADMIN_PROD_ROLLBACK);
            return null;
            
        } else {
            assignLastRollbackDeployment();
            if(!pageMessagesMap.isEmpty()){
                return null;
            }
            if ((!lastRollbackDeployment.isEmpty()) && ((promotion.Is_Rolled_Back__c == true) ||(!deploymentStatusSet.contains(lastRollbackDeployment[0].Status__c)))) {
                deployment = deploymentWillBeRedirected = lastRollbackDeployment[0];
            } else {
                generateRollbackDeployment();
                if(!pageMessagesMap.isEmpty()){
                    return null;
                }
                deployment = deploymentWillBeRedirected = rollbackDeployment;
            }
    
            initializeServiceClasses();
            return goToNextStep();
        }
    }
}