@IsTest
private class NotificationTest {

    @TestSetup
    static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void mergeJson() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withOnlySystemDefault() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels().receiver(null).persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withSystemSubscription() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(false))
                .persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withOnlyUserDefault() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels().persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserSubscription() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserDefaultAndSystemSubscription() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(true));
            new NotificationDefaultChannels().persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserSubscriptionAndSystemDefault() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels().receiver(null);
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserAndSystemSubscription() {
        System.runAs(getRunAsUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
            new NotificationDefaultChannels().receiver(null).add(new NotificationSubscription());
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            // Exercise

            Test.startTest();
            new Notification('Notification1', recipientIds, getMergeJson()).send();

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }

    // HELPER

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }


    private static List<MC_Notification__mdt> mockNotification() {
        return new List<MC_Notification__mdt>{
            new MC_Notification__mdt(
                Subject__c = 'Sample Subject for {Username}',
                Template__c = 'Sample content for {JobName}',
                Active__c = true,
                DeveloperName = 'Notification1',
                MasterLabel = 'Notification1',
                Description__c = 'Description'
            )
        };
    }


    private static Map<String, String> getMergeJson() {
        return new Map<String, String>{
            'Username' => 'Sample User',
            'JobName' => 'D-0001'
        };
    }
}