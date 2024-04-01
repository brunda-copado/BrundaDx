@IsTest
@SuppressWarnings('PMD.AvoidHardcodingId')
private class PackageVersionPublishActionTest {
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
    private static void publish() {
        System.runAs(getStandardUser()) {
            // Setup

            DataHelper helper = new DataHelper()
                .createAPIKey()
                .createMockFunction()
                .createJobTemplate()
                .createJobStep()
                .multiCloudAutomationMock()
                .functionCompletionEvent(true, '', '04t7Q00000090xtQAA');

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Create_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {package_name} was created successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b><a href="{PackageLink}">{PackageName}</a></b> was successfully created.'
                )
            };

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('My Pipeline', true, repo.Id, true);
            pipeline.Platform__c = 'Other';
            insert pipeline;

            helper.createPackage(pipeline.Id, repo.Id).createPackageVersion();

            FunctionEngine.mockResponse = helper.result;

            // Exercise

            PackageVersionPublishAction.publish(
                new List<PackageVersionPublishAction.Request>{ new PackageVersionPublishAction.Request(helper.version.Id) }
            );

            // Verify

            List<JobExecution__c> jobs = [SELECT DataJson__c FROM JobExecution__c];
            System.assertEquals(false, jobs.isEmpty(), 'Job execution should be started.');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.PUBLISH_PACKAGE_VERSION, events[0].Action_Name__c, 'Action Name should match');

            Artifact_Version__c resultVersion = [SELECT Is_released__c FROM Artifact_Version__c WHERE Id = :helper.version.Id];
            System.assertEquals(true, resultVersion.Is_released__c, 'Is Releases should be set to true');

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        }
    }

    @IsTest
    private static void publishWithActionCallback() {
        System.runAs(getStandardUser()) {
            // Setup

            DataHelper helper = new DataHelper()
                .createAPIKey()
                .createMockFunction()
                .createJobTemplate()
                .createJobStep()
                .multiCloudAutomationMock()
                .functionCompletionEvent(true, '', '04t7Q00000090xtQAA');

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Create_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {package_name} was created successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b><a href="{PackageLink}">{PackageName}</a></b> was successfully created.'
                )
            };

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('My Pipeline', true, repo.Id, true);
            pipeline.Platform__c = 'Other';
            insert pipeline;

            helper.createPackage(pipeline.Id, repo.Id).createPackageVersion();

            FunctionEngine.mockResponse = helper.result;

            PackageVersionPublishAction.Request request = new PackageVersionPublishAction.Request(helper.version.Id);
            request.actionCallback = 'ActionCallbackMock';

            // Exercise

            List<PackageVersionPublishAction.Response> response = PackageVersionPublishAction.publish(
                new List<PackageVersionPublishAction.Request>{ request }
            );

            // Verify

            PackageVersionPublishAction.Request requestData = (PackageVersionPublishAction.Request) JSON.deserialize(
                response.get(0).job.DataJson__c,
                PackageVersionPublishAction.Request.class
            );
            System.assertNotEquals(null, requestData.actionCallback, 'Action callback parameter is populated');
        }
    }

    @IsTest
    private static void publishWithNoJobTemplate() {
        System.runAs(getStandardUser()) {
            // Setup

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('My Pipeline', true, repo.Id, true);
            insert pipeline;

            DataHelper helper = new DataHelper().createPackage(pipeline.Id, repo.Id).createPackageVersion();

            Artifact_Version__c version = helper.version;

            PackageVersionPublishAction.Request publishRequest = new PackageVersionPublishAction.Request(version.Id);

            // Exercise

            Exception expectedException;

            Test.startTest();
            try {
                new PackageVersionPublishAction(publishRequest).publish();
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
    private static void publishWithInvalidVersionId() {
        System.runAs(getStandardUser()) {
            // Setup

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('My Pipeline', true, repo.Id, true);
            insert pipeline;

            new DataHelper().multiCloudAutomationMock();

            Exception expectedException = null;
            PackageVersionPublishAction.Request publishRequest = new PackageVersionPublishAction.Request(UserInfo.getUserId());

            // Exercise

            try {
                new PackageVersionPublishAction(publishRequest).publish();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertEquals(Label.InvalidPackageVersionId, expectedException.getMessage(), 'Package version should be missing');
        }
    }

    @IsTest
    private static void publishWithInvalidPipelineId() {
        System.runAs(getStandardUser()) {
            // Setup

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            DataHelper helper = new DataHelper().createPackage(null, repo.Id).createPackageVersion();

            Artifact_Version__c version = helper.version;

            new DataHelper().multiCloudAutomationMock();

            PackageVersionPublishAction.Request publishRequest = new PackageVersionPublishAction.Request(version.Id);
            Exception expectedException = null;

            // Exercise

            try {
                new PackageVersionPublishAction(publishRequest).publish();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertEquals(Label.NoPipelineLinkedToPackage, expectedException.getMessage(), 'Pipeline should be missing');
        }
    }

    @IsTest
    private static void executeWithErrorStatus() {
        System.runAs(getStandardUser()) {
            // Setup

            Git_Repository__c repo = TestDataFactory.createGitRepository();
            insert repo;

            DataHelper helper = new DataHelper().createPackage(null, repo.Id).createPackageVersion();

            Map<String, Object> dataMap = new Map<String, Object>();
            dataMap.put('packageVersionId', helper.version.Id);
            String dataJSON = JSON.serialize(dataMap);
            JobExecution__c job = (JobExecution__c) new JobExecution().status(JobExecutionConstants.STATUS_ERROR).dataJSON(dataJSON).persist();

            // Exercise

            Test.startTest();
            new PackageVersionPublishAction().execute(job, JobExecutionConstants.STATUS_ERROR);
            Test.stopTest();

            // Verify

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.PUBLISH_PACKAGE_VERSION, events[0].Action_Name__c, 'Action Name should match');

            Artifact_Version__c resultVersion = [SELECT Is_released__c FROM Artifact_Version__c WHERE Id = :helper.version.Id];
            System.assertEquals(false, resultVersion.Is_released__c, 'Is Releases should be set to false');

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
        }
    }

    // HELPER

    private class DataHelper {
        private MC_Result__e result;
        private Artifact__c pkg;
        private JobTemplate__c template;
        private Artifact_Version__c version;

        private DataHelper functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
            result = new MC_Result__e();
            result.IsFinished__c = true;
            result.Result_Data__c = data;
            result.IsSuccess__c = isSuccess;
            result.Error_Message__c = errorMessage;

            return this;
        }

        private DataHelper multiCloudAutomationMock() {
            MultiCloudAutomationsSelector.mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>{
                'Other' => new List<MultiCloudAutomation__mdt>{
                    new MultiCloudAutomation__mdt(
                        MasterLabel = 'PublishPackageVersionAction',
                        DeveloperName = 'PublishPackageVersionAction',
                        Action__c = 'PublishPackageVersion',
                        Job_Template__c = 'TestVersionPublish_1'
                    )
                }
            };
            return this;
        }

        private DataHelper createAPIKey() {
            insert new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId(), API_Key__c = DeployAPI.encryptAPIKey('000111222333'));
            return this;
        }

        private DataHelper createMockFunction() {
            Function__c function = new Function__c();
            function.API_Name__c = 'MockedFunction';
            function.Script__c = 'echo hi';
            insert function;
            return this;
        }

        private DataHelper createJobTemplate() {
            template = new JobTemplate__c(Name = 'TestVersionPublish', Version__c = 1);
            insert template;
            return this;
        }

        private DataHelper createJobStep() {
            JobStep__c step = new JobStep__c(
                JobTemplate__c = template.Id,
                Type__c = 'Function',
                ConfigJson__c = '{"functionName" : "MockedFunction"}'
            );
            insert step;
            return this;
        }

        private DataHelper createPackage(Id pipelineId, Id repositoryId) {
            pkg = new Artifact__c();
            pkg.Name = 'Testpkg';
            pkg.Pipeline__c = pipelineId;
            pkg.Artifact_Repository__c = repositoryId;
            pkg.RecordTypeId = SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId();
            insert pkg;
            return this;
        }

        private DataHelper createPackageVersion() {
            version = new Artifact_Version__c();
            version.Artifact__c = pkg.Id;
            version.Name = 'ver 0.1';
            version.Version_number__c = '0.1.0.1';
            version.Subscriber_Version_Id__c = '04t7Q00000090xtQAA';
            insert version;

            return this;
        }
    }

    private static User getStandardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}