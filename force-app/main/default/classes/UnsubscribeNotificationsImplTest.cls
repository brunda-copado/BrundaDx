@IsTest
private class UnsubscribeNotificationsImplTest {

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        new User_t()
            .admin()
            .alias('admUsr')
            .assign( new PermissionSetAssignment_t().jobEngine() );
        User stdUsr = (User) new User_t()
            .standard()
            .alias('stdUsr')
            .assign( new PermissionSetAssignment_t().jobEngine() )
            .persist();

        System.runAs(stdUsr) {
            new CopadoLicense().user(stdUsr).enableAll().persist();
        }
    }


    @IsTest
    private static void executeWithoutSubscriptionId() {
        System.runAs(getStdUser()) {

            // Setup

            Exception expectedException;

            CopadoNotifications.SubscribeResult expectedResult;

            String expectedMessage = String.format(Label.MissingRequiredParameters, new List<String> {'SubscriptionId Id'});

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoNotifications.unsubscribe(null);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals(expectedMessage, expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void executeWithNonSubscriptionId() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            Exception expectedException;

            CopadoNotifications.SubscribeResult expectedResult;

            String expectedMessage = 'Attempt to de-reference a null object';

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoNotifications.unsubscribe(user.Id);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals(expectedMessage, expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void executeWithExistingUserSubsAsCopadoUser() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            new NotificationDefaultChannels()
                .receiver(user.Id)
                .add(new NotificationSubscription().subscribed(true))
                .persist();

            CopadoNotifications.SubscribeResult expectedResult;

            Id subscriptionId = [SELECT Id FROM Notification_Subscription__c].Id;

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.unsubscribe(subscriptionId);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(false, expectedResult.subscription.Subscribed__c, 'User has unsubscribed to the given notification');
        }
    }


    @IsTest
    private static void executeWithExistingSubsAsCopadoAdmin() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(true))
                .persist();

            CopadoNotifications.SubscribeResult expectedResult;

            Id subscriptionId = [SELECT Id FROM Notification_Subscription__c].Id;

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.unsubscribe(subscriptionId);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(false, expectedResult.subscription.Subscribed__c, 'User has unsubscribed to the given notification');
        }
    }


    @IsTest
    private static void executeWithExistingUserSubsAsCopadoAdmin() {
        User user = getAdminUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            new NotificationDefaultChannels()
                .receiver(user.Id)
                .add(new NotificationSubscription().subscribed(true))
                .persist();

            CopadoNotifications.SubscribeResult expectedResult;

            Id subscriptionId = [SELECT Id FROM Notification_Subscription__c].Id;

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.unsubscribe(subscriptionId);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(true, expectedResult.subscription.Subscribed__c, 'The subscription remains same due to improper access');
        }
    }


    @IsTest
    private static void executeWithExistingDisabledSubscription() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            new NotificationDefaultChannels()
                .receiver(user.Id)
                .add(new NotificationSubscription().subscribed(false))
                .persist();

            CopadoNotifications.SubscribeResult expectedResult;

            Id subscriptionId = [SELECT Id FROM Notification_Subscription__c].Id;

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.unsubscribe(subscriptionId);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(false, expectedResult.subscription.Subscribed__c, 'No change in the subscription record');
        }
    }


    //HELPER

    private static User getStdUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND Alias = 'stdUsr'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }


    private static User getAdminUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator' AND Alias = 'admUsr'
            LIMIT 1
        ];
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
}