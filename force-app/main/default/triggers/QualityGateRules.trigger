trigger QualityGateRules on Quality_Gate_Rule__c(before insert, before update, after insert, after update, before delete) {
    fflib_SObjectDomain.triggerHandler(QualityGateRules.class);
}