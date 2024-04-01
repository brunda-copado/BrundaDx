@IsTest
private class LoggerTest {

    @TestSetup
    private static void createData() {
        setupUser();
    }


    @IsTest
    private static void logWithoutLevel() {
        System.runAs( standardUser() ) {
            
            // Setup

            Logger.publishEventsDuringTests = true;

            // Exercise

            Logger.error('genericId', 'section', 'message', null, new ApplicationException('Custom Exception'));
            // Note: Only error/warnings are logged if no levels are defined
            Logger.debug('genericId', 'section', 'message', null);
            Test.getEventBus().deliver();

            // Verify

            List<Result__c> results = results();
            System.assertEquals(1, results.size(), 'Result should be created.');

            Result__c r = results[0];
            System.assertEquals('Logger', r.Job_Type__c);
            System.assertNotEquals(null, r.Start_Time__c);
            System.assertEquals(UserInfo.getUserId(), r.OwnerId);
            System.assertEquals('genericId', r.Job_Id__c);
            System.assertEquals('section', r.Progress_Status__c);
            System.assertNotEquals(null, r.Description__c);
            System.assertEquals('ERROR', r.ParentId__c);
            System.assertNotEquals(null, r.Result_Data__c);
            System.assertEquals('ERROR', r.Error_Code__c);
            System.assertNotEquals(null, r.Error_Message__c);
            System.assertEquals('Failed', r.Status__c);
        }
    }


    @IsTest
    private static void logAboveUserLevel() {
        System.runAs( standardUser() ) {
            
            // Setup

            Logger.publishEventsDuringTests = true;
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId(), Minimum_Logging_Level__c = 2);

            // Exercise

            Logger.info('genericId', 'section', '', new List<Object>{ new Account() });
            Test.getEventBus().deliver();

            // Verify

            Result__c r = results().get(0);
            System.assertEquals('INFO', r.ParentId__c);
            System.assertNotEquals(null, r.Result_Data__c);
            System.assertEquals('INFO', r.Error_Code__c);
            System.assertEquals(null, r.Error_Message__c);
            System.assertEquals('Success', r.Status__c);
        }
    }


    @IsTest
    private static void noLogBelowUserLevel() {
        System.runAs( standardUser() ) {
            
            // Setup

            Logger.publishEventsDuringTests = true;
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId(), Minimum_Logging_Level__c = 2);

            // Exercise

            Logger.trace('genericId', 'section', 'message', null);
            Test.getEventBus().deliver();

            // Verify

            List<Result__c> result = results();
            System.assertEquals(0, result.size(), 'Result should be created.');
        }
    }


    @IsTest
    private static void logAboveOrgLevel() {
        System.runAs( standardUser() ) {
            
            // Setup

            Logger.publishEventsDuringTests = true;
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Minimum_Logging_Level__c = 2);

            // Exercise

            Logger.warning('genericId', 'section', 'message', null);
            Test.getEventBus().deliver();

            // Verify

            List<Result__c> result = results();
            System.assertEquals(1, result.size(), 'Result should be created.');
        }
    }


    @IsTest
    private static void noLogBelowOrgLevel() {
        System.runAs( standardUser() ) {
            
            // Setup

            Logger.publishEventsDuringTests = true;
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId());
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Minimum_Logging_Level__c = 2);

            // Exercise

            Logger.debug('genericId', 'section', 'message', null);
            Test.getEventBus().deliver();

            // Verify

            List<Result__c> result = results();
            System.assertEquals(0, result.size(), 'Result should be created.');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }


    private static User standardUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }


    private static List<Result__c> results() {
        return [
            SELECT
                Job_Type__c,
                Start_Time__c,
                OwnerId,
                Job_Id__c,
                Progress_Status__c,
                Description__c,
                ParentId__c,
                Result_Data__c,
                Error_Code__c,
                Error_Message__c,
                Status__c
            FROM Result__c
        ];
    }
}