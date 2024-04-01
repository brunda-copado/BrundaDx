trigger Tests on Test__c(before insert, before update) {
    fflib_SObjectDomain.triggerHandler(Tests.class);
}