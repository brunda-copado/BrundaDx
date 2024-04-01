public with sharing class PublishNotificationsEvent {
    private List<Copado_Notification__c> notifications;

    // CONSTRUCTOR

    public PublishNotificationsEvent(List<Copado_Notification__c> notifications) {
        this(notifications, null);
    }

    public PublishNotificationsEvent(List<Copado_Notification__c> notifications, Map<Id, Copado_Notification__c> old) {
        this.notifications = filter(notifications, old);
    }

    // PUBLIC

    public List<Database.SaveResult> execute() {
        List<Event__e> result = new List<Event__e>();

        for (Copado_Notification__c notification : notifications) {
            result.add(createEvent(notification));
        }

        return Eventbus.publish(result);
    }

    // PRIVATE

    private List<Copado_Notification__c> filter(List<Copado_Notification__c> notifications, Map<Id, Copado_Notification__c> old) {
        List<Copado_Notification__c> result = new List<Copado_Notification__c>();

        for (Copado_Notification__c notification : notifications) {
            if (isTypeGit(notification)) {
                if (isFinishedRelevant(notification, old?.get(notification.Id)) || old == null) {
                    result.add(notification);
                }
            }
        }

        return result;
    }

    private Event__e createEvent(Copado_Notification__c notification) {
        return new Event__e(
            Publisher_Code__c = 'Copado Backend',
            Topic_URI__c = getTopicUri(notification),
            Payload__c = JSON.serialize(notification)
        );
    }

    private String getTopicUri(Copado_Notification__c notification) {
        return '/events/copado/v1/commit/' + notification.ParentId__c + '/finished=' + notification.isFinished__c + '&success=' + notification.isSuccess__c;
    }

    private Boolean isTypeGit(Copado_Notification__c notification) {
        return (notification.Type__c == 'GitCommit' || notification.Type__c == 'GitDeletion');
    }

    private Boolean isFinishedRelevant(Copado_Notification__c notification, Copado_Notification__c oldNotification) {
        return (!notification.isFinished__c || (notification.isFinished__c != oldNotification?.isFinished__c));
    }
}