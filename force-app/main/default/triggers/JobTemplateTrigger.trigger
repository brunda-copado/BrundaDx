trigger JobTemplateTrigger on JobTemplate__c (after delete, after insert, after update, before delete, before insert, before update) {
    fflib_SObjectDomain.triggerHandler(JobTemplateTrigger.class);
}