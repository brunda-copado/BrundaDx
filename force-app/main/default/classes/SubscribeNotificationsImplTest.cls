@IsTest
private class SubscribeNotificationsImplTest {

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
    private static void executeWithIncompleteRequest() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            Exception expectedException;

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;

            String expectedMessage = String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String> {'Notification Name', 'Receiver Id', 'Channel'}, ', ') });

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoNotifications.subscribe(request);
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
    private static void executeWithCompleteRequest() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'Email';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.subscribe(request);
            Test.stopTest();

            // Verify

            Notification_Default_Channels__c defaultChannel = [SELECT Id, Receiver__c FROM Notification_Default_Channels__c WHERE Receiver__c =: user.Id];

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(defaultChannel.Id, expectedResult.subscription.User_Default_Notification__c, 'Default Notification Id matches');
            System.assertEquals(true, expectedResult.subscription.Subscribed__c, 'User has subscribed to the given notification');
            System.assertEquals('Notification1', expectedResult.subscription.Notification_Name__c, 'User has subscribed to the given notification');
        }
    }


    @IsTest
    private static void executeWithExistingDefaultChannel() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(user.Id).channels('Email').persist();

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'Email';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.subscribe(request);
            Test.stopTest();

            // Verify

            Notification_Default_Channels__c defaultChannel = [SELECT Id, Receiver__c FROM Notification_Default_Channels__c WHERE Receiver__c =: user.Id];

            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(defaultChannel.Id, expectedResult.subscription.User_Default_Notification__c, 'Default Notification Id matches');
            System.assertEquals(true, expectedResult.subscription.Subscribed__c, 'User has subscribed to the given notification');
            System.assertEquals('Notification1', expectedResult.subscription.Notification_Name__c, 'User has subscribed to the given notification');
        }
    }


    @IsTest
    private static void executeWithIncorrectChannel() {
        User user = getStdUser();
        System.runAs(user) {
            // Setup

            Exception expectedException;
            NotificationsSelector.mockNotifications = mockNotification();

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'SMS';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            try{
                CopadoNotifications.subscribe(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals(Label.InvalidNotificationChannel, expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void executeWithExistingSubscription() {
        User user = getStdUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            new NotificationDefaultChannels()
                .receiver(user.Id)
                .add(new NotificationSubscription().subscribed(true))
                .persist();

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'Email';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.subscribe(request);
            Test.stopTest();

            // Verify

            System.assertEquals(1, [SELECT COUNT() FROM Notification_Subscription__c], 'There is only 1 subscription record');
            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(true, expectedResult.subscription.Subscribed__c, 'User remains subscribed to the given notification');
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

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'Email';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.subscribe(request);
            Test.stopTest();

            // Verify

            System.assertEquals(1, [SELECT COUNT() FROM Notification_Subscription__c], 'There is only 1 subscription record');
            System.assertNotEquals(null, expectedResult.subscription.Id, 'Response contains subscription record');
            System.assertEquals(true, expectedResult.subscription.Subscribed__c, 'User has subscribed to the given notification');
        }
    }


    @IsTest
    private static void executeWithCompleteRequestIncorrectAccess() {
        User user = getAdminUser();
        System.runAs(user) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            CopadoNotifications.SubscribeResult expectedResult;

            CopadoNotifications.SubscribeRequest request = new CopadoNotifications.SubscribeRequest();
            request.receiverId = user.Id;
            request.channel = 'Email';
            request.notificationName = 'Notification1';

            // Exercise

            Test.startTest();
            expectedResult = CopadoNotifications.subscribe(request);
            Test.stopTest();

            // Verify
            
            System.assertEquals(null, expectedResult.subscription.Id, 'No subscription record is created');
            System.assertEquals(0, [SELECT COUNT() FROM Notification_Default_Channels__c], 'No Notification Default Channel record is created');
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