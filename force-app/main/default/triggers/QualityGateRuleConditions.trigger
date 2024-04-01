trigger QualityGateRuleConditions on Quality_Gate_Rule_Condition__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(QualityGateRuleConditions.class);
}