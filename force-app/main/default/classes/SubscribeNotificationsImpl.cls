public with sharing class SubscribeNotificationsImpl {
    private CopadoNotifications.SubscribeRequest request;

    // CONSTRUCTOR


    public SubscribeNotificationsImpl(CopadoNotifications.SubscribeRequest request) {
        this.request = request;
    }


    // PUBLIC STATIC


    public static CopadoNotifications.SubscribeResult execute(CopadoNotifications.SubscribeRequest request) {
        if (String.isBlank(request?.notificationName) || String.isBlank(request?.channel) || request?.receiverId == null) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters,
                new List<Object>{ String.join(new List<String> {'Notification Name', 'Receiver Id', 'Channel'}, ', ') })
            );
        } else if (!request.channel.equalsIgnoreCase('Email')) {
            throw new ApplicationException(Label.InvalidNotificationChannel);
        }

        return new SubscribeNotificationsImpl(request).execute();
    }


    // PUBLIC


    public CopadoNotifications.SubscribeResult execute() {
        Notification_Subscription__c subscription = new Notification_Subscription__c();

        if (LicenseHelper.isCCMEnabled()) {
            List<Notification_Default_Channels__c> defaultChannel = new NotificationDefaultChannelsSelector()
            .byUserAndNotificationName(new Set<Id>{ request.receiverId }, request.notificationName);

            if(defaultChannel.isEmpty()) {
                subscription = asSubscription(asDefaultChannel());
            } else if(!defaultChannel.isEmpty() && defaultChannel[0].Notification_Subscriptions__r.isEmpty()){
                subscription = asSubscription(defaultChannel[0]);
            } else {
                Id subId = defaultChannel[0]?.Notification_Subscriptions__r?.Id;
                subscription = updateSubscription(subId);
            }
        }

        return new CopadoNotifications.SubscribeResult(subscription);

    }


    // PRIVATE


    private Notification_Default_Channels__c asDefaultChannel() {
        Notification_Default_Channels__c result = new Notification_Default_Channels__c(
            Channels__c = 'Email',
            Receiver__c = request.receiverId
        );

        DML.safeInsert(result, String.format(Label.ErrorWhileInserting,
            new List<String> {Notification_Default_Channels__c.SObjectType.getDescribe().getLabel(), 'SubscribeNotificationsImpl.asDefaultChannel'})
        );

        return result;
    }


    private Notification_Subscription__c asSubscription(Notification_Default_Channels__c defaultChannel) {
        Notification_Subscription__c result = new Notification_Subscription__c(
            Channels__c = 'Email',
            Subscribed__c = true,
            Notification_Name__c = request.notificationName,
            User_Default_Notification__c = defaultChannel.Id
        );

        DML.safeInsert(result, String.format(Label.ErrorWhileInserting,
            new List<String> {Notification_Subscription__c.SObjectType.getDescribe().getLabel(), 'SubscribeNotificationsImpl.asSubscription'})
        );

        return result;
    }


    private Notification_Subscription__c updateSubscription(Id subscriptionId) {
        Notification_Subscription__c result = new Notification_Subscription__c(
            Id = subscriptionId,
            Subscribed__c = true
        );

        DML.safeUpdate(result, String.format(Label.ErrorWhileUpdating,
            new List<String> {Notification_Subscription__c.SObjectType.getDescribe().getLabel(), 'SubscribeNotificationsImpl.updateSubscription'})
        );

        return new NotificationSubscriptionsSelector().byId(subscriptionId);
    }
}