@isTest
private class JobExecutionMonitorCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createTestData();
        }
    }

    @isTest
    private static void executeWithInProgressJobs() {
        System.runAs(standardUser()) {
            // Setup

            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Manual Task')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Not Started'))
                );
            new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('MT')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Not Started'))
                );
            new JobExecution()
                .status('Successful')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Task for User')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Success'))
                )
                .persist();

            // Exercise

            Test.startTest();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Promotion__c.getLocalName();

            List<Id> result = JobExecutionMonitorCtrl.getJobIds(promotion.Id, fieldName);
            Test.stopTest();

            // Verify

            System.assertEquals(2, result.size(), 'There are 2 JE\'s in \'In Progress\' or \'Not Started\' status.');
        }
    }

    @isTest
    private static void executeWithCompletedJobs() {
        System.runAs(standardUser()) {
            // Setup

            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            new JobExecution()
                .status('Error')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Manual Task')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Failed'))
                );
            new JobExecution()
                .status('Successful')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Task for User')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Success'))
                )
                .persist();

            // Exercise

            Test.startTest();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Promotion__c.getLocalName();

            List<Id> result = JobExecutionMonitorCtrl.getJobIds(promotion.Id, fieldName);
            Test.stopTest();

            // Verify

            System.assertEquals(1, result.size(), 'The most recent completed JE is fetched');
        }
    }

    @isTest
    private static void executeWithNoRelatedJobs() {
        System.runAs(standardUser()) {
            // Setup

            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            // Exercise

            Test.startTest();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Promotion__c.getLocalName();

            List<Id> result = JobExecutionMonitorCtrl.getJobIds(promotion.Id, fieldName);
            Test.stopTest();

            // Verify

            System.assertEquals(0, result.size(), 'The record Id and field Name fetches no job');
        }
    }

    @isTest
    private static void executeWithIncorrectRecordId() {
        User user = standardUser();
        System.runAs(user) {
            // Exercise

            Test.startTest();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Promotion__c.getLocalName();

            List<Id> result = JobExecutionMonitorCtrl.getJobIds(user.Id, fieldName);
            Test.stopTest();

            // Verify

            System.assertEquals(0, result.size(), 'The record Id and field Name fetches no job');
        }
    }

    @isTest
    private static void executeWithNoRecordId() {
        System.runAs(standardUser()) {
            // Setup
            Exception expectedException;
            String fieldName = (String) SObjectType.JobExecution__c.fields.Promotion__c.getLocalName();

            // Exercise

            Test.startTest();
            try {
                JobExecutionMonitorCtrl.getJobIds(null, fieldName);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Script-thrown exception', expectedException.getMessage(), 'Exception message should match');
        }
    }

    @isTest
    private static void executeWithIncorrectFieldName() {
        System.runAs(standardUser()) {
            // Setup

            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            new JobExecution()
                .status('Error')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Manual Task')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Failed'))
                );
            new JobExecution()
                .status('Successful')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Task for User')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Success'))
                )
                .persist();

            // Exercise

            Test.startTest();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Name.getLocalName();

            List<Id> result = JobExecutionMonitorCtrl.getJobIds(promotion.Id, fieldName);
            Test.stopTest();

            // Verify

            System.assertEquals(0, result.size(), 'The combination of field name and record Id gives no record');
        }
    }

    @isTest
    private static void executeWithNoFieldName() {
        System.runAs(standardUser()) {
            //Setup

            Exception expectedException;

            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            new JobExecution()
                .status('Error')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Manual Task')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Failed'))
                );
            new JobExecution()
                .status('Successful')
                .template(template.Id)
                .promotion(promotion.Id)
                .add(
                    new JobStep()
                        .name('Task for User')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Success'))
                )
                .persist();

            // Exercise

            Test.startTest();
            try {
                JobExecutionMonitorCtrl.getJobIds(promotion.Id, '');
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Script-thrown exception', expectedException.getMessage(), 'Exception message should match');
        }
    }

    @isTest
    private static void executeWithNoRecordIdAndNoField() {
        System.runAs(standardUser()) {
            //Setup

            Exception expectedException;

            // Exercise

            Test.startTest();
            try {
                JobExecutionMonitorCtrl.getJobIds(null, '');
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Script-thrown exception', expectedException.getMessage(), 'Exception message should match');
        }
    }

    // HELPER

    private static void createTestData() {
        //Environment creation
        for (Integer i = 0; i < 3; i++) {
            new Environment().name('Environment ' + i).type('Production/Developer').platform('Other');
        }
        new Environment().name('Test Environment 3').type('Production/Developer').platform('Other').persist();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c ORDER BY CreatedDate];

        // Org Credential validation
        List<Org__c> credentials = [
            SELECT Id, Name, Environment__c, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
            FROM Org__c
            WHERE Platform__c = 'Other'
        ];
        for (Org__c org : credentials) {
            org.Username__c = UserInfo.getUserName();
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            org.Oauth_Signature__c = org.Name;
            org.Validated_Date__c = System.now();
            org.Disable_Validation__c = true;
            break;
        }
        update credentials;

        new JobTemplate().name('Sample');

        // Deployment flow creation
        new Pipeline()
            .active(true)
            .mainBranch('master')
            .setPlatform('Other')
            .add(new Connection().sourceId(environments[0].Id).destinationId(environments[2].Id).branch('dev1'))
            .add(new Connection().sourceId(environments[1].Id).destinationId(environments[2].Id).branch('dev2'))
            .add(new Project().add(new UserStory().status('Approved').credentialId(credentials[0].Id)))
            .persist();
    }

    private static User standardUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}