public inherited sharing class CreateDefaultOrg {

    List<Environment__c> environments;

    // CONSTRUCTOR

    public CreateDefaultOrg(List<Environment__c> environments) {
        this.environments = filterNonSalesforce(environments);
    }


    // PUBLIC
    
    public void execute() {
        List<Org__c> defaultOrgs = new List<Org__c>();

        for(Environment__c environment : environments) {
            defaultOrgs.add(asDefaultOrg(environment));
        }

        Utilities.Secure_DML(defaultOrgs, Utilities.DML_Action.INS, schema.SObjectType.Org__c);
    }


    // PRIVATE

    private Org__c asDefaultOrg(Environment__c environment) {
        Org__c result = new Org__c();
        result.Name = environment.Name;
        result.Default_Credential__c = true;
        result.Disable_Validation__c = true;
        result.Environment__c = environment.Id;
        result.Username__c = UserInfo.getName();
        result.Validated_Date__c = System.now();
        result.Org_Type__c = environment.Type__c;

        return result;
    }


    private List<Environment__c> filterNonSalesforce(List<Environment__c> environments) {
        List<Environment__c> result = new List<Environment__c>();

        for(Environment__c environment : environments) {
            if(String.isNotBlank(environment.Platform__c) && environment.Platform__c != 'Salesforce') {
                result.add(environment);
            }
        }

        return result;
    }
}