public inherited sharing class NotificationSubscriptionsSelector extends fflib_SObjectSelector {

    // CONSTRUCTOR

    public NotificationSubscriptionsSelector() {
        this(true, true);
    }

    public NotificationSubscriptionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Notification_Subscription__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Notification_Subscription__c.Channels__c,
            Notification_Subscription__c.Notification_Name__c,
            Notification_Subscription__c.Subscribed__c,
            Notification_Subscription__c.User_Default_Notification__c
        };
    }

    public Notification_Subscription__c byId(Id subscriptionId) {
        List<Notification_Subscription__c> result = (List<Notification_Subscription__c>) Database.query(
            selectFields()
                .setCondition(' Id =:subscriptionId ')
                .toSOQL()
        );

        return (result.isEmpty() ? null : result[0]);
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectField('User_Default_Notification__r.Receiver__c');
    }
}