public inherited sharing class NotificationDefaultChannelsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public NotificationDefaultChannelsSelector() {
        this(true, true);
    }

    public NotificationDefaultChannelsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Notification_Default_Channels__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Notification_Default_Channels__c.Receiver__c,
            Notification_Default_Channels__c.Channels__c
        };
    }

    public List<Notification_Default_Channels__c> byUserIdWithSubscriptions(Set<Id> recipientIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(Notification_Default_Channels__c.Receiver__c + ' IN :recipientIds');

        new NotificationSubscriptionsSelector().addQueryFactorySubselect(query);

        return Database.query(query.toSOQL());
    }

    public List<Notification_Default_Channels__c> byUserAndNotificationName(
        Set<Id> recipientIds,
        String notificationName
    ) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(Notification_Default_Channels__c.Receiver__c + ' IN :recipientIds');

        new NotificationSubscriptionsSelector()
            .addQueryFactorySubselect(query)
            .setCondition(Notification_Subscription__c.Notification_Name__c + ' = :notificationName')
            .setLimit(1);

        return Database.query(query.toSOQL());
    }


    public Notification_Default_Channels__c systemDefaultByName(String notificationName) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(Notification_Default_Channels__c.Receiver__c + ' = null');

        new NotificationSubscriptionsSelector()
            .addQueryFactorySubselect(query)
            .setCondition(Notification_Subscription__c.Notification_Name__c + ' = :notificationName')
            .setLimit(1);


        List<Notification_Default_Channels__c> result = Database.query(query.toSOQL());
        return result.isEmpty() ? null : result[0];
    }
}