public with sharing class CalculateQGCScopeWeight { 

    private Quality_Gate_Rule_Condition__c qualityGateRuleCondition;

    private Map<String, Integer> weightByField = new Map<String, Integer>{ 'Platform__c' => 5, 'Pipeline__c' => 10, 'Stage__c' => 15, 'Environment__c' => 20};

    // CONSTRUCTOR

    public CalculateQGCScopeWeight(Quality_Gate_Rule_Condition__c qualityGateRuleCondition) {
        this.qualityGateRuleCondition = qualityGateRuleCondition;
    }

    // PUBLIC

    public Integer execute() {
        return getScopeWeights();
    }

    // PRIVATE

    private Integer getScopeWeights() {
        Integer result = 0;
        for (String fieldName : weightByField.keyset()) {
            if (qualityGateRuleCondition.get(fieldName) != null) {
                result += weightByField.get(fieldName);
            }
        }
        return result;
    }
}