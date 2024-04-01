public with sharing class NotificationsCenterCtrl {

    // PUBLIC

    @AuraEnabled
    public static Boolean isCopadoAdmin() {
        try {
            return LicenseHelper.isCopadoEnabled();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }


    @AuraEnabled
    public static Boolean isCopadoUser() {
        try {
            return LicenseHelper.isCCMEnabled();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }


    @AuraEnabled
    public static Notification getDefaultNotification(Id userId) {
        // Note: userId is null for System Default Notification
        try {
            Notification result = new Notification();

            Notification_Default_Channels__c userNotification = getNotificationWithSubscriptions(userId);
            
            Notification_Default_Channels__c systemNotification = userId != null
                ? getNotificationWithSubscriptions(null)
                : userNotification;

            result.id = userNotification?.Id;
            result.channels = getDefaultChannels(userNotification, systemNotification);
            result.subscriptions = asSubscriptions(
                                        userNotification?.Notification_Subscriptions__r,
                                        systemNotification?.Notification_Subscriptions__r
                                    );

            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static List<Subscription> asSubscriptions(
        List<Notification_Subscription__c> userSubscriptions,
        List<Notification_Subscription__c> systemSubscriptions
    ) {
        List<Subscription> result = new List<Subscription>();

        Map<String, Notification_Subscription__c> userSubscriptionByName = groupByName(userSubscriptions);
        Map<String, Notification_Subscription__c> systemSubscritionByName = groupByName(systemSubscriptions);

        for (MC_Notification__mdt mcNotification : new NotificationsSelector().byActive(true)) {
            Notification_Subscription__c userSubscription = userSubscriptionByName.get(mcNotification.DeveloperName);
            Notification_Subscription__c systemSubscription = systemSubscritionByName.get(mcNotification.DeveloperName);

            result.add( asSubscription(mcNotification, userSubscription, systemSubscription) );
        }

        return result;
    }


    private static Map<String, Notification_Subscription__c> groupByName(List<Notification_Subscription__c> subscriptions) {
        Map<String, Notification_Subscription__c> result = new Map<String, Notification_Subscription__c>();

        if (subscriptions != null) {
            for (Notification_Subscription__c subscription : subscriptions) {
                result.put(subscription.Notification_Name__c, subscription);
            }
        }

        return result;
    }


    private static Subscription asSubscription(
        MC_Notification__mdt mcNotification,
        Notification_Subscription__c userSubscription,
        Notification_Subscription__c systemSubscription
    ) {
        Boolean isSystmOverridden = (userSubscription != null);

        Subscription result = new Subscription(userSubscription?.Id, mcNotification);
        result.subscribed = isSystmOverridden
                            ? userSubscription?.Subscribed__c
                            : (systemSubscription == null)
                                ? true
                                : systemSubscription?.Subscribed__c;
        result.channels = isSystmOverridden ? userSubscription?.Channels__c : 'User Default';
        result.channels = 'User Default'; // Hardcoded till next release
        return result;
    }


    private static Notification_Default_Channels__c getNotificationWithSubscriptions(Id userId) {
        List<Notification_Default_Channels__c> result = new NotificationDefaultChannelsSelector()
                                                            .byUserIdWithSubscriptions(new Set<Id>{ userId });
        return result.isEmpty() ? null : result[0];
    }


    private static List<String> getDefaultChannels(
        Notification_Default_Channels__c dfaultNotification,
        Notification_Default_Channels__c systmNotification
    ) {
        List<String> result = dfaultNotification != null
                                ? dfaultNotification?.Channels__c?.split(';')
                                : systmNotification?.Channels__c?.split(';');

        //return result == null ? new List<String>() : result;
        return new List<String>{ 'Email' };
    }

    // INNER

    public class Notification {
        @AuraEnabled
        public Id id;

        @AuraEnabled
        public List<String> channels;

        @AuraEnabled
        public List<Subscription> subscriptions;
    }

    
    public class Subscription {
        @AuraEnabled
        public Id id;

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String developerName;

        @AuraEnabled
        public String description;

        @AuraEnabled
        public Boolean subscribed;

        @AuraEnabled
        public String channels;

        // CTOR

        public Subscription(Id id, MC_Notification__mdt mcNotification) {
            this.id = id;
            this.label = mcNotification.MasterLabel;
            this.description = mcNotification.Description__c;
            this.developerName = mcNotification.DeveloperName;
        }

        public Subscription(Id id, MC_Notification__mdt mcNotification, Boolean subscribed) {
            this.id = id;
            this.label = mcNotification.MasterLabel;
            this.description = mcNotification.Description__c;
            this.developerName = mcNotification.DeveloperName;
            this.subscribed = subscribed;
        }
    }
}