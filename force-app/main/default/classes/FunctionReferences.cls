public with sharing class FunctionReferences {

    // PUBLIC

    @AuraEnabled
    public static List<Step> getReferences(Id recordId) {
        List<Step> result = new List<Step>();

        try {
            String functionApiName = getFunctionApiName(recordId);

            for (JobStep__c step : [
                SELECT Name, JobTemplate__r.Name, ConfigJson__c
                FROM JobStep__c
                WHERE JobTemplate__c != NULL AND Type__c = 'Function'
                WITH SECURITY_ENFORCED
            ]) {
                String stepFunctionApiName = getStepFunctionApiName(step.ConfigJson__c);

                if (functionApiName == stepFunctionApiName) {
                    result.add( new Step(step) );
                }
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }

        return result;
    }

    // PRIVATE

    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static String getStepFunctionApiName(String configJson) {
        String result;

        try {
            JobEngine.StepConfig config = (JobEngine.StepConfig) JSON.deserialize(configJson, JobEngine.StepConfig.class);
            result = config.functionName;
        } catch(Exception ex) {
            // Note: Do nothing if any step has incorrect Config
        }

        return result;
    }

    private static String getFunctionApiName(Id recordId) {
        List<Function__c> function = [
            SELECT API_Name__c
            FROM Function__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (function.isEmpty()) {
            throw new ApplicationException(Label.Invalid_Function_Id);
        }

        return function[0].API_Name__c;
    }

    // INNER

    public class Step {
        @AuraEnabled
        public String id;

        @AuraEnabled
        public String name;

        @AuraEnabled
        public String parentId;

        @AuraEnabled
        public String parentName;

        @AuraEnabled
        public String type;

        // CTOR

        public Step(JobStep__c step) {
            this.id = step.Id;
            this.name = step.Name;
            this.type = 'Job Step';
            this.parentId = step.JobTemplate__c;
            this.parentName = step.JobTemplate__r.Name;
        }
    }
}