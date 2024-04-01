public with sharing class CreateStandardRecordCtrl {

    @AuraEnabled
    public static List<SupportedObject> getSupportedObjects() {
        List<SupportedObject> result = new List<SupportedObject>();

        try {
            for(SupportedObject__mdt supportedObject : new SupportedObjectsSelector().allExposed()) {
                result.add(new SupportedObject(supportedObject.SObject__r?.Label, supportedObject.SObject__r?.QualifiedApiName));
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static List<NestedRecord> getNestedRecords(Id jobTemplateId) {
        List<NestedRecord> result = new List<NestedRecord>();
        List<JobStep__c> jobSteps = [SELECT Id, Name, ConfigJson__c, Type__c FROM JobStep__c WHERE JobTemplate__c = :jobTemplateId WITH USER_MODE];

        Set<String> functionNames = functionNames(jobSteps);
        List<Function__c> functions = [SELECT Id, API_Name__c, Name FROM Function__c WHERE API_Name__c IN :functionNames WITH USER_MODE];
        if(functionNames.size() != functions.size()) {
            throwExceptionFor(functionNames, functions);
        }

        result.addAll(asNestedRecord(jobSteps, 'Job Step'));
        result.addAll(asNestedRecord(functions, 'Function'));

        return result;
    }


    @AuraEnabled
    public static String getRecordBundle(List<Id> recordIds) {
        String result;

        try {
            result = CreateStandardRecords.serialize(new Set<Id>(recordIds));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }


    // PRIVATE

    private static List<NestedRecord> asNestedRecord(List<SObject> records, String type) {
        List<NestedRecord> result = new List<NestedRecord>();

        for(SObject record: records) {
            result.add(new NestedRecord(record.Id, (String) record.get('Name'), type));
        }

        return result;
    }


    private static void throwExceptionFor(Set<String> allFunctionNames, List<Function__c> functions) {
        Set<String> existingFunctionNames = new Set<String>();
        Set<String> invalidFunctionNames = new Set<String>();

        for(Function__c function : functions) {
            existingFunctionNames.add(function.API_Name__c);
        }

        for(String allFunctionName : allFunctionNames) {
            if(!existingFunctionNames.contains(allFunctionName)) {
                invalidFunctionNames.add(allFunctionName);
            }
        }

        throw new ApplicationException(Label.InvalidFunctionReference + String.join(new List<String>(invalidFunctionNames), ', '));
    }

	private static Set<String> functionNames(List<JobStep__c> jobSteps) {
        Set<String> result = new Set<String>();

        for(JobStep__c jobStep : jobSteps) {
            if (jobStep.Type__c == 'Function') {
                JobEngine.StepConfig config = (JobEngine.StepConfig) JSON.deserialize(jobStep.ConfigJson__c, JobEngine.StepConfig.class);
                result.add(String.valueOf(config.functionName));
            }
        }

        return result;
	}

    // INNER

    public class NestedRecord {
        @AuraEnabled
        public String id;

        @AuraEnabled
        public String type;

        @AuraEnabled
        public String name;


        public NestedRecord(String id, String name, String type) {
            this.id = id;
            this.name = name;
            this.type = type;
        }
    }


    public class SupportedObject {
        @AuraEnabled
        public String label;

        @AuraEnabled
        public String value;

        public SupportedObject(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}