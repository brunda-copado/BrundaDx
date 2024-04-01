@IsTest
private class ResultMonitorLWCHandlerTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }

    @IsTest
    private static void promotionExecutionTest() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup
            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            Promotion__c promotion = [SELECT Id, Last_Promotion_Execution_Id__c FROM Promotion__c LIMIT 1];
            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Test')
                        .order(1)
                        .configJson('{"type" : "QRT"}')
                        .result(new Result().jobType('Test').status('In Progress'))
                )
                .add(
                    new JobStep()
                        .name('Fill details')
                        .type('Manual')
                        .order(2)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Not Started'))
                )
                .persist();

            promotion.Last_Promotion_Execution_Id__c = job.Id;
            update promotion;

            JobExecution__c subJob = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add(
                    new JobStep()
                        .name('Sub Step Manual')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "Manual"}')
                        .result(new Result().jobType('Manual').status('Success'))
                )
                .add(
                    new JobStep()
                        .name('Manual Task Step 2')
                        .type('Manual')
                        .order(2)
                        .configJson('{"type" : "Manual"}')
                        .result(new Result().jobType('Manual').status('In Progress'))
                )
                .persist();

            List<JobStep__c> step = [SELECT Sub_Job_Execution__c FROM JobStep__c WHERE Type__c = 'Test'];
            step[0].Sub_Job_Execution__c = subJob.Id;
            update step;

            // Exercise
            Test.startTest();
            String objectName = (String) SObjectType.Promotion__c.getLocalName();
            String fieldName = (String) SObjectType.Promotion__c.fields.Last_Promotion_Execution_Id__c.getLocalName();

            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(promotion.Id, objectName, fieldName);
            Test.stopTest();

            // Verify
            Id testStepResult = [SELECT Id FROM Result__c WHERE Status__c = 'In Progress' AND Job_Type__c = 'Manual' LIMIT 1].Id;
            Id manualStepResult = [SELECT Id FROM Result__c WHERE Status__c = 'Not Started' AND Job_Type__c = 'Manual' LIMIT 1].Id;

            System.assertEquals('Sample', actualResult.mainTitle, 'Same as promotion template name');
            System.assertEquals(job.Id, actualResult.jobExecutionId, 'Same as job execution id');
            System.assertEquals('step1', actualResult.resultDetails[0].jobStepLabel, 'Same as step name');
            System.assertEquals('Test', actualResult.resultDetails[0].jobStepType, 'Same as step type');
            System.assertEquals(testStepResult, actualResult.resultDetails[0].resultId, 'The result Id is of last step');
            System.assertEquals('Manual', actualResult.resultDetails[1].jobStepType, 'Same as step type');
            System.assertEquals('Not Started', actualResult.resultDetails[1].resultStatus, 'Same as result status');
            System.assertEquals(manualStepResult, actualResult.resultDetails[1].resultId, 'The result id matches');
            System.assertNotEquals(3, actualResult.resultDetails.size(), 'There should be 3 results in the actualResult');
            System.assertEquals(null, actualResult.jobExecutionErrorMessage, 'There is no error message');
        }
    }

    @IsTest
    private static void deploymentExecutionTest() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup
            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            Promotion__c promotion = [SELECT Id, Last_Deployment_Execution_Id__c FROM Promotion__c LIMIT 1];
            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .result(new Result().jobType('Function').status('In Progress'))
                )
                .add(
                    new JobStep()
                        .name('step2')
                        .type('Test')
                        .order(2)
                        .configJson('{"type" : "QRT"}')
                        .result(new Result().jobType('Test').status('Not Started'))
                )
                .persist();

            promotion.Last_Deployment_Execution_Id__c = job.Id;
            update promotion;

            JobExecution__c subJob = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .result(new Result().jobType('Function').status('In Progress'))
                )
                .persist();

            List<JobStep__c> step = [SELECT Id, Sub_Job_Execution__c FROM JobStep__c WHERE Type__c = 'Test'];
            step[0].Sub_Job_Execution__c = subJob.Id;
            update step;

            // Exercise
            Test.startTest();
            String objectName = (String) SObjectType.Promotion__c.getLocalName();
            String fieldName = (String) SObjectType.Promotion__c.fields.Last_Deployment_Execution_Id__c.getLocalName();

            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(promotion.Id, objectName, fieldName);
            Test.stopTest();

            // Verify
            System.assertEquals('Sample', actualResult.mainTitle, 'Same as promotion template name');
            System.assertEquals(job.Id, actualResult.jobExecutionId, 'Same as job execution id');
            System.assertEquals('step1', actualResult.resultDetails[0].jobStepLabel, 'Same as step name');
            System.assertEquals('step2', actualResult.resultDetails[1].jobStepLabel, 'Same as step name');
            System.assertEquals('Function', actualResult.resultDetails[0].jobStepType, 'Same as step type');
            System.assertEquals('Test', actualResult.resultDetails[1].jobStepType, 'Same as step type');
            System.assertEquals('Not Started', actualResult.resultDetails[1].resultStatus, 'Same as result status');
            System.assertNotEquals(3, actualResult.resultDetails.size(), 'There should be 3 results in the actualResult');
            System.assertEquals(null, actualResult.jobExecutionErrorMessage, 'As the job is in progress, there is no error message');
        }
    }

    @IsTest
    private static void executionWithJobExecutionId() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .result(new Result().jobType('Function').status('In Progress'))
                )
                .persist();

            // Exercise

            Test.startTest();
            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(job.Id, '', '');
            Test.stopTest();

            // Verify
            System.assertEquals('Sample', actualResult.mainTitle, 'Title should be JE Name');
            System.assertEquals(job.Id, actualResult.jobExecutionId, 'Same as job execution id');
            System.assertEquals('step1', actualResult.resultDetails[0].jobStepLabel, 'Same as step name');
            System.assertEquals('Function', actualResult.resultDetails[0].jobStepType, 'Same as step type');
            System.assertEquals('In Progress', actualResult.resultDetails[0].resultStatus, 'Same as result status');
            System.assertEquals(1, actualResult.resultDetails.size(), 'There should be 1 result in the actualResult');
        }
    }

    @IsTest
    private static void executionWithoutTemplateTest() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Manual')
                        .order(1)
                        .configJson('{"type" : "QRT1"}')
                        .result(new Result().jobType('Manual').status('Not Started'))
                )
                .persist();

            // Exercise

            Test.startTest();
            String objectName = (String) SObjectType.JobExecution__c.getLocalName();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Id.getLocalName();

            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(job.Id, objectName, fieldName);
            Test.stopTest();

            // Verify
            System.assertEquals([SELECT Name FROM JobExecution__c WHERE Id = :job.Id].Name, actualResult.mainTitle, 'Title should be JE Name');
            System.assertEquals(job.Id, actualResult.jobExecutionId, 'Same as job execution id');
            System.assertEquals('step1', actualResult.resultDetails[0].jobStepLabel, 'Same as step name');
            System.assertEquals('Manual', actualResult.resultDetails[0].jobStepType, 'Same as step type');
            System.assertEquals('Not Started', actualResult.resultDetails[0].resultStatus, 'Same as result status');
            System.assertEquals(1, actualResult.resultDetails.size(), 'There should be 1 result in the actualResult');
        }
    }

    @IsTest
    private static void promotionWithoutJobExecutionTest() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup
            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();

            Promotion__c promotion = [SELECT Id, Last_Promotion_Execution_Id__c FROM Promotion__c LIMIT 1];

            // Exercise
            Test.startTest();
            String objectName = (String) SObjectType.Promotion__c.getLocalName();
            String fieldName = (String) SObjectType.Promotion__c.fields.Last_Promotion_Execution_Id__c.getLocalName();

            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(promotion.Id, objectName, fieldName);
            Test.stopTest();

            // Verify
            System.assertEquals(null, actualResult.mainTitle, 'The title for result monitor should remain blank');
            System.assertEquals(null, actualResult.jobExecutionId, 'There should be no job execution');
            System.assertEquals(0, actualResult.resultDetails.size(), 'There should be no results in the actualResult');
            System.assertEquals('Not Started', actualResult.jobExecutionStatus, 'Job status should be not started');
            System.assertEquals(null, actualResult.jobTemplateId, 'There should be no job template');
            System.assertEquals('', actualResult.jobExecutionErrorMessage, 'As there is no job, error message is blank');
        }
    }

    @IsTest
    private static void jobExecutionWithErrorMessage() {
        User user = getRunAsUser();
        System.runAs(user) {
            // Setup
            new Function().apiName('MockedFunction').script('echo hi').persist();
            JobTemplate__c template = [SELECT Id FROM JobTemplate__c LIMIT 1];

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Failed')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .result(new Result().jobType('Function').status('Failed').errMsg('There was an error'))
                )
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction"}'))
                .errorMsg('There was an error')
                .persist();

            // Exercise
            Test.startTest();
            String objectName = (String) SObjectType.JobExecution__c.getLocalName();
            String fieldName = (String) SObjectType.JobExecution__c.fields.Id.getLocalName();

            ResultStatusDetail actualResult = ResultMonitorLWCHandler.result(job.Id, objectName, fieldName);
            Test.stopTest();

            // Verify
            System.assertEquals('Sample', actualResult.mainTitle, 'Title should be job template Name');
            System.assertEquals(job.Id, actualResult.jobExecutionId, 'Same as job execution id');
            System.assertEquals('step1', actualResult.resultDetails[0].jobStepLabel, 'Same as step name');
            System.assertEquals('Function', actualResult.resultDetails[0].jobStepType, 'Same as step type');
            System.assertEquals('Failed', actualResult.resultDetails[0].resultStatus, 'Same as result status');
            System.assertEquals('There was an error', actualResult.jobExecutionErrorMessage, 'Same as job error message');
        }
    }

    // HELPER

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

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

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}