public with sharing class UnsubscribeNotificationsImpl {
    // PUBLIC

    public static CopadoNotifications.SubscribeResult execute(Id subscriptionId) {
        if (subscriptionId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String>{ 'SubscriptionId Id' }));
        }

        Notification_Subscription__c subscription = new NotificationSubscriptionsSelector().byId(subscriptionId);

        if (
            (subscription.User_Default_Notification__r.Receiver__c != null && LicenseHelper.isCCMEnabled()) ||
            (subscription.User_Default_Notification__r.Receiver__c == null && LicenseHelper.isCopadoEnabled())
        ) {
            DML.safeUpdate(
                new Notification_Subscription__c(Id = subscriptionId, Subscribed__c = false),
                String.format(
                    Label.ErrorWhileUpdating,
                    new List<String>{ Notification_Subscription__c.SObjectType.getDescribe().getLabel(), 'UnsubscribeNotificationsImpl.execute' }
                )
            );
        }

        return new CopadoNotifications.SubscribeResult(subscriptionId);
    }
}