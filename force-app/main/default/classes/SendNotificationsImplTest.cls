@IsTest
private class SendNotificationsImplTest {

    @TestSetup
    private static void setupData() {
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
    private static void executeWithIncompleteRequest() {
        User user = getUser();
        System.runAs(user) {

            // Setup

            Exception expectedException;

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.recipientIds = new Set<Id>{ user.Id };
            String expectedMessage = String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String> {'Notification Name', 'Recipient Ids', 'Merge Data'}, ', ') });

            // Exercise

            Test.startTest();
            try {
                CopadoNotifications.send(request);
            } catch(Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(expectedMessage, expectedException.getMessage(), 'Exception message should match.');
            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void executeWithCompleteRequest() {
        User user = getUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ user.Id };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withOnlySystemDefault() {
        User user = getUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null).persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ user.Id };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withSystemSubscription() {
        System.runAs(getUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(false))
                .persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withOnlyUserDefault() {
        System.runAs(getUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserSubscription() {
        User user = getUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ user.Id };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserDefaultAndSystemSubscription() {
        User user = getUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(true));
            new NotificationDefaultChannels().persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ user.Id };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserSubscriptionAndSystemDefault() {
        System.runAs(getUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null);
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    @IsTest
    private static void withUserAndSystemSubscription() {
        System.runAs(getUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null).add(new NotificationSubscription());
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
            request.name = 'Notification1';
            request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
            request.mergeData = getMergeJson();

            // Exercise

            Test.startTest();
            CopadoNotifications.send(request);

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            Test.stopTest();
        }
    }


    //HELPER

    private static User getUser() {
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