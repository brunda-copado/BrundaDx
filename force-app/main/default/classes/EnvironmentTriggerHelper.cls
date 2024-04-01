public with sharing class EnvironmentTriggerHelper {

    private List<Environment__c> environments;

    
    // CONSTRUCTOR

    public EnvironmentTriggerHelper(List<Environment__c> environments, Map<Id, Environment__c> oldEnvironments) {
        this.environments = filter(environments, oldEnvironments);
    }


    // PUBLIC

    public void execute() {
        updateOrgCredential();
    }


    // PRIVATE

    private void updateOrgCredential() {
        List<Org__c> orgsToUpdate = [SELECT Id, Environment__c, SFDC_Org_ID__c, Validated_Date__c, Oauth_Signature__c FROM Org__c WHERE Environment__c IN :environments];
        Map<Id, Environment__c> environmentsById = new Map<Id, Environment__c>(environments);

        for(Org__c org : orgsToUpdate) {
            List<String> orgIds = org.SFDC_Org_ID__c.split('_', 2);

            org.Validated_Date__c = null;
            org.Oauth_Signature__c = null;
            
            if(!orgIds.isEmpty()) {
                orgIds[0] = environmentsById.get(org.Environment__c)?.Org_ID__c;
                org.SFDC_Org_ID__c = String.join(orgIds, '_');
            }
        }
            
        Utilities.Secure_DML(orgsToUpdate, Utilities.DML_Action.UPS, schema.SObjectType.Org__c);
    }
    

    private List<Environment__c> filter(List<Environment__c> environments, Map<Id, Environment__c> oldEnvironments) {
        
        List<Environment__c> result = new List<Environment__c>();

        for(Environment__c environment : environments) {
            Environment__c oldEnvironment = oldEnvironments.get(environment.Id);

            if(environment?.Org_ID__c != oldEnvironment?.Org_ID__c ) {
                result.add(environment);
            }
        }

        return result;
    }
}