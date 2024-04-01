public with sharing class ManualStepCtrl {

    @InvocableMethod
    public static List<String> getInstruction(List<Id> stepIds) {
        String result = null;

        JobStep__c step = new JobStepsSelector().byId(stepIds[0]);

        if(String.isNotBlank(step.ConfigJson__c)) {
            result = instruction(step.ConfigJson__c);
        }

        return new List<String> { result };
    }

    private static String instruction(String configJson) {
        String result;

        try {
            Map<String, Object> stepConfig = (Map<String, Object>) Json.deserializeUntyped(configJson);
            result = (String) stepConfig.get('instructions');
        }
        catch (Exception ex) {
            result = null;
        }

        return result;
    }
}