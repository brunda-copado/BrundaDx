@IsTest
public with sharing class NotificationDefaultChannels extends DomainBuilder {
    public NotificationDefaultChannels() {
        super(Notification_Default_Channels__c.SObjectType);

        channels('Email');
        receiver(UserInfo.getUserId());
    }

    public NotificationDefaultChannels add(NotificationSubscription subscription) {
        return (NotificationDefaultChannels) subscription.setParent(
            Notification_Subscription__c.User_Default_Notification__c,
            this
        );
    }

    public NotificationDefaultChannels channels(String channels) {
        return (NotificationDefaultChannels) set(Notification_Default_Channels__c.Channels__c, channels);
    }
    
    public NotificationDefaultChannels receiver(Id userId) {
        return (NotificationDefaultChannels) set(Notification_Default_Channels__c.Receiver__c, userId);
    }
}