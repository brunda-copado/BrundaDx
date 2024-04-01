trigger DataTemplates on Data_Template__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(DataTemplates.class);
}