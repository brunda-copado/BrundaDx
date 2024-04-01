@IsTest
private class NotificationsCenterCtrlTest {

    @TestSetup
    private static void makeData() {
        setupUser();
    }


    @IsTest
    private static void withCopadoUserLicense() {
        System.runAs(getStdUser()) {
    
            // Exercise

            Boolean isCopadoUser = NotificationsCenterCtrl.isCopadoUser();

            // Verify

            System.assertEquals(true, isCopadoUser, 'User should have Copado User License.');
        }
    }


    @IsTest
    private static void withCopadoAdminLicense() {
        System.runAs(getStdUser()) {
            
            // Exercise

            Boolean isCopadoAdmin = NotificationsCenterCtrl.isCopadoAdmin();

            // Verify

            System.assertEquals(true, isCopadoAdmin, 'User should have Copado Admin License.');
        }
    }


    @IsTest
    private static void withoutCopadoUserLicense() {
        System.runAs(getAdminUser()) {
            
            // Exercise

            Boolean isCopadoUser = NotificationsCenterCtrl.isCopadoUser();

            // Verify

            System.assertEquals(false, isCopadoUser, 'User should not have Copado User License.');
        }
    }


    @IsTest
    private static void withoutCopadoAdminLicense() {
        System.runAs(getAdminUser()) {

            // Exercise

            Boolean isCopadoAdmin = NotificationsCenterCtrl.isCopadoAdmin();

            // Verify

            System.assertEquals(false, isCopadoAdmin, 'User should not have Copado Admin License.');
        }
    }


    @IsTest
    private static void noMcNotifications() {
        System.runAs(getStdUser()) {

            // Setup

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(null);

            // Verify

            System.assertEquals(null, result.id, 'Default notification should not be present.');
            System.assertEquals(1, result.channels.size(), 'Notification channels should be empty.');
            System.assertEquals(0, result.subscriptions.size(), 'Subscriptions should be empty.');
        }
    }


    @IsTest
    private static void noDefaults() {
        System.runAs(getStdUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(null);

            // Verify

            System.assertEquals(null, result.id, 'Default notification should not be present.');
            System.assertEquals(1, result.channels.size(), 'Notification channels should be empty.');
            System.assertEquals(1, result.subscriptions.size(), 'Notification should be auto subscribed.');

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];
            System.assertEquals(null, s.id, 'Subscription Id should be empty.');
            System.assertEquals('Notification1', s.developerName, 'Subscription Name should be correct.');
            System.assertEquals('Description', s.description, 'Subscription Description should be correct.');
            System.assertEquals(true, s.subscribed, 'Notification should be subscribed.');
            System.assertEquals('User Default', s.channels, 'Subscription Channels should be correct.');
        }
    }


    @IsTest
    private static void onlySystemDefault() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null).persist();

            // Exercise

            NotificationsCenterCtrl.Notification sysResult = NotificationsCenterCtrl.getDefaultNotification(null);
            NotificationsCenterCtrl.Notification usrResult = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            Notification_Default_Channels__c d = fetchDefaultNotification(null);

            System.assertEquals(d.Id, sysResult.id, 'System Default should be present.');
            System.assertEquals(1, sysResult.subscriptions.size(), 'Notification should be auto subscribed.');
            System.assertEquals(null, sysResult.subscriptions[0].id, 'Subscription Id should be empty.');

            System.assertEquals(null, usrResult.id, 'User Default should be present.');
            System.assertEquals(1, usrResult.subscriptions.size(), 'Notification should be auto subscribed.');
            System.assertEquals(null, usrResult.subscriptions[0].id, 'Subscription Id should be empty.');
        }
    }


    @IsTest
    private static void onlySystemDefaultWithSubscription() {
        System.runAs(getStdUser()) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(false))
                .persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(null);

            // Verify

            Notification_Default_Channels__c d = fetchDefaultNotification(null);
            System.assertEquals(1, result.subscriptions.size(), 'Notification should have subscriptions.');

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];
            System.assertEquals(d.Notification_Subscriptions__r[0].Id, s.id, 'Subscription Id should not be empty.');
            System.assertEquals(false, s.subscribed, 'Notification should not be subscribed.');
        }
    }


    @IsTest
    private static void onlyUserDefault() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            Notification_Default_Channels__c d = fetchDefaultNotification(u.Id);

            System.assertEquals(d.Id, result.id, 'User default should be present.');
            System.assertEquals(1, result.subscriptions.size(), 'Notification should be auto subscribed.');
            System.assertEquals(null, result.subscriptions[0].id, 'Subscription Id should be empty.');
        }
    }


    @IsTest
    private static void onlyUserDefaultWithSubscription() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().add(new NotificationSubscription()).persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            Notification_Default_Channels__c d = fetchDefaultNotification(u.Id);
            System.assertEquals(1, result.subscriptions.size(), 'Subscription should be present.');

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];
            System.assertEquals(d.Notification_Subscriptions__r[0].Id, s.id, 'Subscription Id should not be empty.');
        }
    }


    @IsTest
    private static void userAndSystemDefaultsAndNoSubscription() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null).persist();
            new NotificationDefaultChannels().persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            Notification_Default_Channels__c d = fetchDefaultNotification(u.Id);
            System.assertEquals(d.Id, result.id, 'User Default should be returned.');
            System.assertEquals(1, result.subscriptions.size(), 'Notification should have subscriptions.');

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];
            System.assertEquals(null, s.id, 'Subscription Id should be empty.');
            System.assertEquals(true, s.subscribed, 'Notification should be subscribed.');
        }
    }


    @IsTest
    private static void userSubscriptionAndSystemDefaults() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels().receiver(null).persist();
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(false)).persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];

            Notification_Subscription__c ns = [SELECT Subscribed__c FROM Notification_Subscription__c WHERE Id = :s.id];
            System.assertEquals(ns.Id, s.id, 'Subscription Id should match users.');
            System.assertEquals(ns.Subscribed__c, s.subscribed, 'Notification subscription should match users.');
        }
    }


    @IsTest
    private static void userDefaultsAndSystemSubscription() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(false))
                .persist();
            new NotificationDefaultChannels().persist();

            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];
            Notification_Subscription__c ns = [SELECT Subscribed__c FROM Notification_Subscription__c LIMIT 1];

            System.assertEquals(null, s.id, 'Subscription Id should be empty.');
            System.assertEquals(ns.Subscribed__c, s.subscribed, 'Notification subscription should match systems.');
        }
    }


    @IsTest
    private static void userAndSystemSubscription() {
        User u = getStdUser();
        System.runAs(u) {

            // Setup

            NotificationsSelector.mockNotifications = mockNotification();
            new NotificationDefaultChannels()
                .receiver(null)
                .add(new NotificationSubscription().subscribed(false))
                .persist();
            new NotificationDefaultChannels().add(new NotificationSubscription().subscribed(true)).persist();
            
            // Exercise

            NotificationsCenterCtrl.Notification result = NotificationsCenterCtrl.getDefaultNotification(u.Id);

            // Verify

            NotificationsCenterCtrl.Subscription s = result.subscriptions[0];

            Notification_Subscription__c ns = [
                SELECT Subscribed__c
                FROM Notification_Subscription__c
                WHERE Id = :s.id AND User_Default_Notification__r.Receiver__c = :u.Id
            ];
            System.assertEquals(ns.Id, s.id, 'Subscription Id should match users.');
            System.assertEquals(ns.Subscribed__c, s.subscribed, 'Notification subscription should match users.');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User stdUsr = (User) new User_t()
            .standard()
            .alias('stdUsr')
            .assign( new PermissionSetAssignment_t().jobEngine() )
            .persist();

        User admUsr = (User) new User_t()
            .admin()
            .alias('admUsr')
            .assign( new PermissionSetAssignment_t().jobEngine() )
            .persist();

        System.runAs(stdUsr) {
            new CopadoLicense().user(stdUsr).enableAll().persist();
        }
    }


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
                Subject__c = 'Subject',
                Template__c = 'Template',
                Active__c = true,
                DeveloperName = 'Notification1',
                MasterLabel = 'Notification1',
                Description__c = 'Description'
            )
        };
    }

    
    private static Notification_Default_Channels__c fetchDefaultNotification(Id receiver) {
        return [
            SELECT Id, (SELECT Id FROM Notification_Subscriptions__r)
            FROM Notification_Default_Channels__c
            WHERE Receiver__c = :receiver
            LIMIT 1
        ];
    }
}