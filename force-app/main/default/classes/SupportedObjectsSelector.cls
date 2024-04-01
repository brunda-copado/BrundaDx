public inherited sharing class SupportedObjectsSelector {

    @TestVisible
    private static Map<String, String> mock = new Map<String, String>();

    @TestVisible
    private static List<SupportedObject__mdt>  mockRecords = new List<SupportedObject__mdt> ();

    public Map<String, String> all() {
        Map<String, String> result;

        if(Test.isRunningTest() && !mock.isEmpty()) {
            result = mock;
        }
        else {
            List<SupportedObject__mdt> supportedObjects = [SELECT Id, SObject__r.QualifiedApiName, ExternalIdField__r.QualifiedApiName FROM SupportedObject__mdt WITH SECURITY_ENFORCED];
            result = groupByObject(supportedObjects);
        }

        return result;
    }

    public List<SupportedObject__mdt> allExposed() {
        List<SupportedObject__mdt> result;

        if(Test.isRunningTest() && !mockRecords.isEmpty()) {
            result = mockRecords;
        }
        else {
            result= [SELECT Id, SObject__r.QualifiedApiName, SObject__r.Label FROM SupportedObject__mdt WHERE IsExposed__c = true WITH SECURITY_ENFORCED];
        }

        return result;
    }

    public String byType(String objectType) {
        Map<String, String> all = all();
        
        return all.containsKey(objectType) ? all.get(objectType) : all.get('copado__' + objectType);
    }


    private Map<String, String> groupByObject(List<SupportedObject__mdt> supportedObjects) {
        Map<String, String> result = new Map<String, String>();

        for(SupportedObject__mdt supportedObject : supportedObjects) {
            result.put(supportedObject.SObject__r.QualifiedApiName, supportedObject.ExternalIdField__r.QualifiedApiName);
        }

        return result;
    }
}