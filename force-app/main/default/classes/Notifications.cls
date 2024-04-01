public with sharing class Notifications extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public Notifications(List<Copado_Notification__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new InitializeNotifications(records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new InitializeNotifications(records, (Map<Id, Copado_Notification__c>) old).execute();
    }

    public override void onAfterInsert() {
        new PublishNotificationsEvent(records).execute();
    }

    public override void onAfterUpdate(Map<Id, SObject> old) {
        new PublishNotificationsEvent(records, (Map<Id, Copado_Notification__c>) old).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Notifications(records);
        }
    }
}