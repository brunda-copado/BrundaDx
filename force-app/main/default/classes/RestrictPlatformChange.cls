public with sharing class RestrictPlatformChange {
    private List<Deployment_Flow__c> records;

    // CONSTRUCTOR

    public RestrictPlatformChange(List<Deployment_Flow__c> records, Map<Id, Deployment_Flow__c> old) {
        this.records = filterInvalid(records, old);
    }

    // PUBLIC

    public void run() {
        for (Deployment_Flow__c record : records) {
            record.addError(Label.Platform_Change_Forbidden);
        }
    }

    // PRIVATE

    private List<Deployment_Flow__c> filterInvalid(List<Deployment_Flow__c> records, Map<Id, Deployment_Flow__c> old) {
        List<Deployment_Flow__c> result = new List<Deployment_Flow__c>();

        for (Deployment_Flow__c record : records) {
            Deployment_Flow__c oldRecord = old.get(record.Id);

            if (invalidPlatformUpdate(record.Platform__c, oldRecord.Platform__c)) {
                result.add(record);
            }
        }

        return result;
    }

    private Boolean invalidPlatformUpdate(String newPlatform, String oldPlatform) {
        return oldPlatform != newPlatform && (String.isNotBlank(oldPlatform) || newPlatform != 'Salesforce');
    }
}