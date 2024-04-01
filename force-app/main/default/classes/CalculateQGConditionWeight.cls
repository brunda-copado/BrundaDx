public with sharing class CalculateQGConditionWeight {
    private Quality_Gate_Rule_Condition__c qualityGateRuleCondition;

    // CONSTRUCTOR

    public CalculateQGConditionWeight(Quality_Gate_Rule_Condition__c qualityGateRuleCondition) {
        this.qualityGateRuleCondition = qualityGateRuleCondition;
    }

    // PUBLIC

    public Integer execute() {
        Integer result = new CalculateQGCScopeWeight(qualityGateRuleCondition).execute();
        result += qualityGateRuleCondition.Filter_Criteria__c != null
                    ? new CalculateQGCCriteriaWeight(qualityGateRuleCondition.Filter_Criteria__c).execute() 
                    : 0;

        return result;
    }
}