trigger Stages on Stage__c (before delete) {
    fflib_SObjectDomain.triggerHandler(Stages.class);
}