// Note: Channels Hardcoded as we have only support email right now
@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class SendNotificationsImpl {
    private static final String SENDER_NAME = 'copado';
    private MC_Notification__mdt notification;
    private CopadoNotifications.SendRequest request;

    private Notification_Subscription__c systemSubscription;
    private Map<Id, Notification_Subscription__c> usersSubscriptions;

    // CONSTRUCTOR

    public SendNotificationsImpl(CopadoNotifications.SendRequest request) {
        this.request = request;
        this.notification = parse( new NotificationsSelector().byName(request?.name), request?.mergeData );
    }


    // PUBLIC STATIC

    public static void execute(CopadoNotifications.SendRequest request) {
        if (String.isBlank(request?.name) || request?.recipientIds.isEmpty() || request?.mergeData.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters,
                new List<Object>{ String.join(new List<String> {'Notification Name', 'Recipient Ids', 'Merge Data'}, ', ') })
            );
        }

        new SendNotificationsImpl(request).execute();
    }


    // PUBLIC

    public void execute() {
        if (notification != null) {
            systemSubscription = getSystemSubscription();
            usersSubscriptions = getUserSubscriptions();

            Map<String, Set<Id>> recipientsByChannel = groupRecipientsByChannel();
            Set<Id> recipientIds = recipientsByChannel.get('Email');

            if(recipientIds != null && !recipientIds.isEmpty()) {
                sendEmail(getEmailsFor(recipientIds));
            }
        }
    }


    // PRIVATE


    private Map<String, Set<Id>> groupRecipientsByChannel() {
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();

        for (Id recipientId : request?.recipientIds) {
            List<String> channels = getUsersChannels(recipientId);

            for (String channel : channels) {
                if (result.containsKey(channel)) {
                    result.get(channel).add(recipientId);
                } else {
                    result.put(channel, new Set<Id>{ recipientId });
                }
            }
        }

        return result;
    }


    private Notification_Subscription__c getSystemSubscription() {
        Notification_Subscription__c result;

        Notification_Default_Channels__c systemDefault = new NotificationDefaultChannelsSelector().systemDefaultByName(request?.name);

        if (systemDefault != null && !systemDefault.Notification_Subscriptions__r.isEmpty()) {
            result = systemDefault.Notification_Subscriptions__r[0];
        }

        return result;
    }


    private List<String> getUsersChannels(Id recipientId) {
        String result;
        Notification_Subscription__c userSubscription = usersSubscriptions.get(recipientId);

        if (userSubscription == null) {
            result = getChannelsFromSystemSubscription();
        } else {
            result = getChannelsFor(userSubscription);
        }

        return String.isBlank(result) ? new List<String>() : result.split(';');
    }


    private String getChannelsFromSystemSubscription() {
        String result;

        if (systemSubscription == null || systemSubscription.Subscribed__c) {
            result = 'Email';
        }

        return result;
    }


    private String getChannelsFor(Notification_Subscription__c userSubscription) {
        String result;

        if(userSubscription?.Subscribed__c == true || (userSubscription == null && (systemSubscription == null || systemSubscription.Subscribed__c))) {
            result = 'Email';
        }

        return result;
    }


    private Map<Id, Notification_Subscription__c> getUserSubscriptions() {
        Map<Id, Notification_Subscription__c> result = new Map<Id, Notification_Subscription__c>();

        for (Notification_Default_Channels__c userChannel : new NotificationDefaultChannelsSelector().byUserAndNotificationName(request?.recipientIds, request?.name)) {
            if(!userChannel.Notification_Subscriptions__r.isEmpty()) {
	            result.put(userChannel.Receiver__c, userChannel.Notification_Subscriptions__r[0]);
            }
        }

        return result;
    }


    private void sendEmail(List<String> emails) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(emails);
        mail.setSenderDisplayName(SENDER_NAME);
        mail.setSubject(notification.Subject__c);
        mail.setHtmlBody( getMessageBody(notification.Template__c) );

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }


    private List<String> getEmailsFor(Set<Id> recipientIds) {
        List<String> result = new List<String>();

        for (User user : new UsersSelector().byId(recipientIds)) {
            result.add(user.Email);
        }

        return result;
    }


    private String getMessageBody(String body) {
        EmailTemplate template = [
            SELECT Id
            FROM EmailTemplate
            WHERE EmailTemplate.DeveloperName = 'MCNotification'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.Id, null, null);

        return (message.htmlbody == null) ? '' : message.htmlbody.replace('emailBody', body);
    }


    private MC_Notification__mdt parse(MC_Notification__mdt notification, Map<String, String> mergeData) {
        notification.Subject__c = parse(notification?.Subject__c, mergeData);
        notification.Template__c = parse(notification?.Template__c, mergeData);

        return notification;
    }


    private String parse(String template, Map<String, String> mergeData) {
        for (String find : mergeData.keySet()) {
            String value = mergeData.get(find);
            value = String.isBlank(value) ? '' : value;
            template = template?.replace('{' + find + '}', value);
        }

        return template;
    }
}