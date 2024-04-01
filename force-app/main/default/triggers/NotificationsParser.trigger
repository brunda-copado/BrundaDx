trigger NotificationsParser on Copado_Notification__c(before insert, before update, after insert, after update) {
    fflib_SObjectDomain.triggerHandler(Notifications.class);
}