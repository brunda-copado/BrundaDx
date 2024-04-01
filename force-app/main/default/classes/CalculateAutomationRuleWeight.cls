public with sharing class CalculateAutomationRuleWeight {
    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static final Map<String, Integer> WEIGHT_BY_FIELD = new Map<String, Integer>{
        Automation_Rule__c.Stage__c.getDescribe().getName() => 5,
        Automation_Rule__c.Environment__c.getDescribe().getName() => 10
    };

    private Automation_Rule__c rule;

    // CONSTRUCTOR

    public CalculateAutomationRuleWeight(Automation_Rule__c rule) {
        this.rule = rule;
    }

    // PUBLIC

    public Integer execute() {
        Integer result = 0;
        for (String fieldName : WEIGHT_BY_FIELD.keyset()) {
            if (rule.get(fieldName) != null) {
                result += WEIGHT_BY_FIELD.get(fieldName);
            }
        }
        return result;
    }
}