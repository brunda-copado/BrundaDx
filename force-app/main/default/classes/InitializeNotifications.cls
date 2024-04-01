public with sharing class InitializeNotifications {
    private List<Copado_Notification__c> notifications;

    // CONSTRUCTOR

    public InitializeNotifications(List<Copado_Notification__c> notifications) {
        this(notifications, null);
    }

    public InitializeNotifications(List<Copado_Notification__c> notifications, Map<Id, Copado_Notification__c> old) {
        this.notifications = filter(notifications, old);
    }

    //PUBLIC

    public void execute() {
        try {
            for (Copado_Notification__c notification : notifications) {
                Map<String, Object> message = (Map<String, Object>) JSON.deserializeUntyped(notification.Message__c);
                String status = message.containsKey('status') ? (String) message.get('status') : '';
    
                if (message.containsKey('isFinished')) {
                    notification.isFinished__c = notification.isFinished__c || (Boolean) message.get('isFinished');
                } else if (String.isNotBlank(status)) {
                    notification.isFinished__c =
                        notification.isFinished__c ||
                        (status == 'done') ||
                        (status == 'Succeeded') ||
                        (status == 'failed') ||
                        status.startsWith('Failed');
                }
    
                notification.Status__c = status;
                notification.isSuccess__c = message.containsKey('isSuccess') ? (Boolean) message.get('isSuccess') : (status == 'Succeeded');
                notification.Matching_Key__c = message.containsKey('matchingKeysString')
                    ? (String) message.get('matchingKeysString')
                    : notification.Matching_Key__c;
                notification.Matching_Key__c = String.isBlank(notification.Matching_Key__c)
                    ? notification.Type__c + '-' + notification.ParentId__c
                    : notification.Matching_Key__c;
            }
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    // PRIVATE

    private List<Copado_Notification__c> filter(List<Copado_Notification__c> notifications, Map<Id, Copado_Notification__c> old) {
        List<Copado_Notification__c> result = new List<Copado_Notification__c>();

        for (Copado_Notification__c notification : notifications) {
            Copado_Notification__c oldNotification = old?.get(notification.Id);

            if (String.isNotBlank(notification.Message__c)) {
                if (old == null || (notification.Message__c != oldNotification?.Message__c)) {
                    result.add(notification);
                }
            }
        }

        return result;
    }
}