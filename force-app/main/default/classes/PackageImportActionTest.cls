@IsTest
private class PackageImportActionTest {
    @TestSetup
    private static void createData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableCopado().persist();
        }
    }

    @IsTest
    private static void multipleRequests() {
        System.runAs(getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            PackageImportAction.Request request = new PackageImportAction.Request(null, null, null);

            // Exercise

            try {
                PackageImportAction.import(new List<PackageImportAction.Request>{ request, request });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assertEquals(Label.OnlyOneRequestAvailable, expectedException.getMessage(), 'Should throw multiple requests exception.');
        }
    }

    @IsTest
    private static void invalidJSON() {
        System.runAs(getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().createPipeline();
            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, '{"devhub": "abc", }');

            // Exercise

            try {
                new PackageImportAction(request).import();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assert(expectedException.getMessage().contains(Label.ERROR_PARSING_JSON), 'JSON exception should be thrown.');
        }
    }

    @IsTest
    private static void repositoryNotLinked() {
        System.runAs(getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().createPipeline();
            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, null);

            // Exercise

            try {
                new PackageImportAction(request).import();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assertEquals(Label.NoGitRepoLinked, expectedException.getMessage(), 'Should throw pipeline not linked to repository exception.');
        }
    }

    @IsTest
    private static void pipelineNotFound() {
        System.runAs(getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().createRepository();
            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.repository.Id, null);

            // Exercise

            try {
                new PackageImportAction(request).import();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assertEquals(Label.InvalidPipelineId, expectedException.getMessage(), 'Should throw invalid pipeline exception.');
        }
    }

    @IsTest
    private static void templateNotFound() {
        System.runAs(getRunAsUser()) {
            // Setup

            DataHelper helper = new DataHelper().createRepository().createPipeline();
            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, null);

            // Exercise

            Exception expectedException;

            Test.startTest();
            try {
                new PackageImportAction(request).import();
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assert(
                expectedException.getMessage().contains(Label.Error_No_Action_Template_Defined),
                'Exception message should match: ' + expectedException.getMessage()
            );
        }
    }

    @IsTest
    private static void import() {
        System.runAs(getRunAsUser()) {
            // Setup

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Import_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {PackageName} was imported successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b<a href="{PackageLink}">{PackageName}</a></b> was imported into the pipeline successfully.'
                )
            };

            DataHelper helper = new DataHelper().createJobTemplate().createRepository().createPipeline();

            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, null);

            PackageImportAction.ResultPayload payload = new PackageImportAction.ResultPayload();
            payload.packageRecord = new Artifact__c(
                Name = 'Test',
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId(),
                Package_Type__c = 'Unlocked',
                Artifact_Repository__c = helper.repository.Id
            );
            payload.packageVersions = new List<Artifact_Version__c>{ new Artifact_Version__c(Name = 'version1') };
            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(payload));

            // Exercise

            Test.startTest();
            List<PackageImportAction.Response> response = PackageImportAction.import(new List<PackageImportAction.Request>{ request });
            Test.stopTest();

            // Verify

            System.assertEquals(1, response.size(), 'Response should not be empty');
            System.assertNotEquals(null, response.get(0).job, 'Job execution should be started.');

            System.assertEquals(1, [SELECT COUNT() FROM Artifact__c], 'One Artifact__c record should have been created');
            System.assertEquals(1, [SELECT COUNT() FROM Artifact_Version__c], 'One Artifact_Version__c record should have been created');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.IMPORT_PACKAGE, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void importWithActionCallback() {
        System.runAs(getRunAsUser()) {
            // Setup

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Import_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {PackageName} was imported successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b<a href="{PackageLink}">{PackageName}</a></b> was imported into the pipeline successfully.'
                )
            };

            DataHelper helper = new DataHelper().createJobTemplate().createRepository().createPipeline();

            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, null);
            request.actionCallback = 'ActionCallbackMock';

            PackageImportAction.ResultPayload payload = new PackageImportAction.ResultPayload();
            payload.packageRecord = new Artifact__c(
                Name = 'Test',
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId(),
                Package_Type__c = 'Unlocked',
                Artifact_Repository__c = helper.repository.Id
            );
            payload.packageVersions = new List<Artifact_Version__c>{ new Artifact_Version__c(Name = 'version1') };
            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(payload));

            // Exercise

            Test.startTest();
            List<PackageImportAction.Response> response = PackageImportAction.import(new List<PackageImportAction.Request>{ request });
            Test.stopTest();

            // Verify

            PackageImportAction.Request requestData = (PackageImportAction.Request) JSON.deserialize(
                response.get(0).job.DataJson__c,
                PackageImportAction.Request.class
            );
            System.assertNotEquals(null, requestData.actionCallback, 'Action callback parameter is populated');
        }
    }

    @IsTest
    private static void packageInfoNotAvailable() {
        System.runAs(getRunAsUser()) {
            // Setup

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Import_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {PackageName} was imported successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b<a href="{PackageLink}">{PackageName}</a></b> was imported into the pipeline successfully.'
                )
            };

            DataHelper helper = new DataHelper().createJobTemplate().createRepository().createPipeline();

            PackageImportAction.Request request = new PackageImportAction.Request(null, helper.pipeline.Id, null);

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise

            Test.startTest();
            List<PackageImportAction.Response> response = PackageImportAction.import(new List<PackageImportAction.Request>{ request });
            Test.stopTest();

            // Verify

            System.assertEquals(1, response.size(), 'Response should not be empty');
            System.assertNotEquals(null, response.get(0).job, 'Job execution should be started.');

            System.assertEquals(0, [SELECT COUNT() FROM Artifact__c], 'No Artifact__c record should have been created');
            System.assertEquals(0, [SELECT COUNT() FROM Artifact_Version__c], 'No Artifact_Version__c record should have been created');
        }
    }

    @IsTest
    private static void getPackageDetailsFromContentVersion() {
        System.runAs(getRunAsUser()) {
            // SETUP

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Import_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {PackageName} was imported successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b<a href="{PackageLink}">{PackageName}</a></b> was imported into the pipeline successfully.'
                )
            };

            DataHelper helper = new DataHelper().createJobTemplate().createRepository().createPipeline();
            JobExecution__c jobExecution = createJobExecution(helper);
            JobStep__c step = getJobStep(jobExecution.Id, 'Import');
            updateJobStepExecution(step, jobExecution.Id);

            createContentVersionAndLink(getResult(step.Id).Id, helper.repository.Id);
            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(getMultipleVersionsPayLoad(helper.repository.Id)));

            // EXERCISE

            Test.startTest();
            new PackageImportAction().execute(jobExecution, 'Successful');
            Test.stopTest();

            // VERIFY

            System.assertEquals(1, [SELECT COUNT() FROM Artifact__c], 'One Artifact__c record should have been created');
            System.assertEquals(300, [SELECT COUNT() FROM Artifact_Version__c], '300 Artifact_Version__c records should have been created');  
        }
    }

    private static void createContentVersionAndLink(Id resultId, Id repositoryId) {
        ContentVersion content = new ContentVersion(
            Title = 'PackageAndVersions.json',
            origin = 'C',
            PathOnClient = 'PackageAndVersions.json',
            VersionData = Blob.valueOf(getMultipleVersionsPayLoad(repositoryId))
        );
        insert content;

        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];

        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = resultId,
            ContentDocumentId = contentVersion.ContentDocumentId
        );
        insert link;
    }

    private static String getMultipleVersionsPayLoad(Id repositoryId) {
        PackageImportAction.ResultPayload payload = new PackageImportAction.ResultPayload();
        payload.packageRecord = new Artifact__c(
            Name = 'Test',
            RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId(),
            Package_Type__c = 'Unlocked',
            Artifact_Repository__c = repositoryId
        );
        
        List<Artifact_Version__c> versions = new List<Artifact_Version__c>();
        for (Integer counter = 0; counter < 300; counter++) {
            versions.add(new Artifact_Version__c(Name = 'version'+counter));
        }
        payload.packageVersions = versions;

        return JSON.serialize(payload);
    }
    
    private static JobExecution__c createJobExecution(DataHelper helper) {
        JobExecution__c execution = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(helper.template.Id)
                .add(new JobStep().name('Import').type('Function').order(1).add(new Result().status('Success')))
                .dataJson(JSON.serialize(new PackageImportAction.Request(null, helper.pipeline.Id, null)))
                .persist();
        return execution;
    }

    private static void updateJobStepExecution(JobStep__c jobStep, Id jobExecutionId) {
        jobStep.JobExecution__c = jobExecutionId;
        update jobStep;
    }

    private static JobStep__c getJobStep(Id jobExecutionId, String stepName) {
        return [SELECT Id, Name, JobExecution__c FROM JobStep__c WHERE JobExecution__c = :jobExecutionId AND Name =:stepName LIMIT 1];
    }

    private static Result__c getResult(Id jobStepId) {
        return [SELECT Id, Name, JobStep__c FROM Result__c WHERE JobStep__c = :jobStepId LIMIT 1];
    }

    // Helper

    private class DataHelper {
        private Git_Repository__c repository;
        private Deployment_Flow__c pipeline;
        private JobTemplate__c template;

        private DataHelper createRepository() {
            repository = new Git_Repository__c();
            repository.Name = 'test repo';
            insert repository;

            return this;
        }

        private DataHelper createPipeline() {
            pipeline = new Deployment_Flow__c();
            pipeline.Name = 'Test Pipeline';
            pipeline.Active__c = true;
            pipeline.Git_Repository__c = repository?.Id;
            pipeline.Enable_Copado_DX__c = true;
            pipeline.Platform__c = 'Other';
            insert pipeline;

            return this;
        }

        private DataHelper createJobTemplate() {
            template = (JobTemplate__c) new JobTemplate().name('PackageImportTemplate').mockAutomation('ImportPackage').add(new JobStep()).persist();

            return this;
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}