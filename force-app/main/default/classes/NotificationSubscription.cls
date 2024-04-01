@IsTest
public with sharing class NotificationSubscription extends DomainBuilder {
    public NotificationSubscription() {
        super(Notification_Subscription__c.sObjectType);

        name('Notification1');
        channels('Email');
        subscribed(true);
    }

    public NotificationSubscription name(String name) {
        return (NotificationSubscription) set(Notification_Subscription__c.Notification_Name__c, name);
    }

    public NotificationSubscription channels(String channels) {
        return (NotificationSubscription) set(Notification_Subscription__c.Channels__c, channels);
    }

    public NotificationSubscription subscribed(Boolean subscribed) {
        return (NotificationSubscription) set(Notification_Subscription__c.Subscribed__c, subscribed);
    }
}