@IsTest
private class WebhookSettingsCtrlTest {

    @TestSetup
    private static void setupData() {
        setupUser();
    }

    @IsTest
    private static void getActionKeys() {
        System.runAs( standardUser() ) {
    
            // Setup

            Datetime now = WebhookSettingsCtrl.NOW;
            Webhook_Settings__c akey1 = (Webhook_Settings__c) new WebhookSetting()
                .startDate(now)
                .endDate(now.addDays(30))
                .key(new Random().string(10) + WebhookSettingsCtrl.USER_API_KEY)
                .persist();

            new WebhookSetting()
                .startDate(now.addDays(-10))
                .endDate(now.addDays(-5))
                .key(new Random().string(10))
                .persist();

            // Exercise

            List<WebhookSettingsCtrl.ActionAPIKey> results = WebhookSettingsCtrl.getActionKeys();

            // Verify

            System.assertEquals(2, results.size(), 'Only 2 records should be returned');
            WebhookSettingsCtrl.ActionAPIKey result = results[0];

            System.assertEquals(akey1.Id, result.id, 'Id should match');
            System.assertEquals(akey1.Key__c, result.key, 'Key should match');
            System.assertEquals(akey1.Action__c, result.actions, 'Actions should match');
            System.assertEquals(akey1.Start_Date__c.date(), result.startDate, 'Start Date should match');
            System.assertEquals(akey1.End_Date__c.date(), result.endDate, 'End Date should match');
            System.assertEquals(akey1.UserId__c, result.userId, 'UserId should match');
            System.assertEquals(false, result.isExpired, 'Is Expired should match');
            System.assertEquals(false, result.isUserApiKeyChanged, 'Is API key changed should match');
            System.assertEquals(UserInfo.getUserEmail(), result.username, 'Username should match');
            System.assertEquals(30, result.expiresInDays, 'Expires in days should match');
            System.assertEquals(true, results[1].isExpired, 'Is Expired should match');
            System.assertEquals(true, results[1].isUserApiKeyChanged, 'Is Expired should match');
        }
    }


    @IsTest
    private static void createActionKey() {
        User usr = standardUser();
        System.runAs(usr) {
        
            // Setup

            Datetime now = WebhookSettingsCtrl.NOW;
            WebhookSettingsCtrl.ActionAPIKey aKeyData = new WebhookSettingsCtrl.ActionAPIKey();
            aKeyData.actions = 'Commit,Promotion';
            aKeyData.expiresInDays = 20;
            aKeyData.userId = usr.Id;

            // Exercise

            WebhookSettingsCtrl.saveActionKey( JSON.serialize(aKeyData) );

            // Verify

            List<Webhook_Settings__c> results = actionApiKeys();
            System.assertEquals(1, results.size(), 'Only 1 record should be created.');

            Webhook_Settings__c aKey = results[0];
            String expectedName = (usr.Id + '_' + now).remove(':');
            Blob partialKey = Blob.valueOf(usr.Id + '' + now);
            String encryptedKey = EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', partialKey));
            String expectedKey = encryptedKey + WebhookSettingsCtrl.USER_API_KEY;

            System.assertEquals(expectedName, aKey.Name, 'Name should match');
            System.assertEquals(expectedKey, aKey.Key__c, 'Key should match');
            System.assertEquals(aKeyData.actions, aKey.Action__c, 'Action should match');
            System.assertEquals(usr.Id, aKey.UserId__c, 'UserId should match');
            System.assertEquals(now, aKey.Start_Date__c, 'Start Date should match');
            System.assertEquals(now.addDays(20), aKey.End_Date__c, 'End Date should match');
        }
    }


    @IsTest
    private static void updateActionKey() {
        User usr = standardUser();
        System.runAs(usr) {
    
            // Setup

            Datetime now = WebhookSettingsCtrl.NOW;
            Webhook_Settings__c aKey = (Webhook_Settings__c) new WebhookSetting()
                .startDate(now.addDays(-30))
                .endDate(now.addDays(30))
                .key(new Random().string(10) + WebhookSettingsCtrl.USER_API_KEY)
                .persist();

            WebhookSettingsCtrl.ActionAPIKey aKeyData = new WebhookSettingsCtrl.ActionAPIKey();
            aKeyData.id = aKey.Id;
            aKeyData.key = aKey.Key__c;
            aKeyData.actions = 'Commit';
            aKeyData.expiresInDays = 20;
            aKeyData.userId = usr.Id;

            // Exercise

            WebhookSettingsCtrl.saveActionKey( JSON.serialize(aKeyData) );

            // Verify

            Webhook_Settings__c aNewKey = actionApiKeys().get(0);

            System.assertEquals(aKey.Name, aNewKey.Name, 'Name should match');
            System.assertEquals(aKey.Key__c, aNewKey.Key__c, 'Key should match');
            System.assertEquals(aKeyData.actions, aNewKey.Action__c, 'Action should match');
            System.assertEquals(usr.Id, aNewKey.UserId__c, 'UserId should match');
            System.assertEquals(now.addDays(-30), aNewKey.Start_Date__c, 'Start Date should match');
            System.assertEquals(now.addDays(20), aNewKey.End_Date__c, 'End Date should match');
        }
    }


    @IsTest
    private static void updateExpiredKey() {
        System.runAs( standardUser() ) {
      
            // Setup

            Datetime now = WebhookSettingsCtrl.NOW;
            Webhook_Settings__c aKey = (Webhook_Settings__c) new WebhookSetting()
                .startDate(now.addDays(-30))
                .endDate(now.addDays(-15))
                .key(new Random().string(10) + WebhookSettingsCtrl.USER_API_KEY)
                .persist();

            WebhookSettingsCtrl.ActionAPIKey aKeyData = new WebhookSettingsCtrl.ActionAPIKey();
            aKeyData.id = aKey.Id;
            aKeyData.actions = 'Commit';
            aKeyData.expiresInDays = 20;
            aKeyData.key = aKey.Key__c;
            aKeyData.userId = UserInfo.getUserId();

            // Exercise

            WebhookSettingsCtrl.saveActionKey( JSON.serialize(aKeyData) );

            // Verify

            Webhook_Settings__c aNewKey = actionApiKeys().get(0);

            System.assertEquals(aKey.Key__c, aNewKey.Key__c, 'Key should match');
            System.assertEquals(aKeyData.actions, aNewKey.Action__c, 'Action should match');
            System.assertEquals(now.addDays(-30), aNewKey.Start_Date__c, 'Start Date should match');
            System.assertEquals(now.addDays(20), aNewKey.End_Date__c, 'End Date should match');
        }
    }


    @IsTest
    private static void updateOnUserApiChange() {
        System.runAs( standardUser() ) {

            // Setup

            Datetime now = WebhookSettingsCtrl.NOW;
            Webhook_Settings__c aKey = (Webhook_Settings__c) new WebhookSetting()
                .startDate(now.addDays(-30))
                .endDate(now.addDays(30))
                .key(new Random().string(10) + WebhookSettingsCtrl.USER_API_KEY)
                .persist();

            WebhookSettingsCtrl.ActionAPIKey aKeyData = new WebhookSettingsCtrl.ActionAPIKey();
            aKeyData.id = aKey.Id;
            aKeyData.actions = 'Commit';
            aKeyData.expiresInDays = 20;
            aKeyData.key = aKey.Key__c;
            aKeyData.isUserApiKeyChanged = true;
            aKeyData.userId = UserInfo.getUserId();

            // Exercise

            WebhookSettingsCtrl.saveActionKey( JSON.serialize(aKeyData) );

            // Verify

            Webhook_Settings__c aNewKey = actionApiKeys().get(0);

            System.assertNotEquals(aKey.Key__c, aNewKey.Key__c, 'Key should match');
            System.assertEquals(aKeyData.actions, aNewKey.Action__c, 'Action should match');
            System.assertEquals(now.addDays(-30), aNewKey.Start_Date__c, 'Start Date should match');
            System.assertEquals(now.addDays(20), aNewKey.End_Date__c, 'End Date should match');
        }
    }


    @IsTest
    private static void deleteWebhookSettings() {
        System.runAs( standardUser() ) {
    
            // Setup

            Webhook_Settings__c aKey = (Webhook_Settings__c) new WebhookSetting().persist();

            // Exercise

            WebhookSettingsCtrl.deleteActionKey(aKey.Id);

            // Verify

            List<Webhook_Settings__c> results = actionApiKeys();

            System.assertEquals(0, results.size(), 'The record should be deleted');
        }
    }


    @IsTest
    private static void missingUserApiKey() {
        System.runAs( standardUser() ) {
    
            // Setup

            Exception expectedException;
            delete [SELECT Id FROM Personal_Settings__c];

            // Exercise

            try {
                WebhookSettingsCtrl.getActionKeys();
            } catch(Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedException, 'Exception should be thrown.');
            System.assertEquals(Label.API_KEY_MISSING, expectedException.getMessage(), 'User API key should be missing.');
        }
    }


    // HELPER

    private static void setupUser() {
        User usr = (User) new User_t()
            .assign( new PermissionSetAssignment_t().copadoUser() )
            .standard()
            .persist();

        System.runAs(usr) {
            insert new Personal_Settings__c(
                SetupOwnerId = usr.Id,
                API_Key__c = DeployAPI.encryptAPIKey('000111222333')
            );
        }
    }


    private static List<Webhook_Settings__c> actionApiKeys() {
        return [SELECT Name, Key__c, Action__c, UserId__c, Start_Date__c, End_Date__c FROM Webhook_Settings__c];
    }


    private static User standardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}