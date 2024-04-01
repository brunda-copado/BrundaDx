@IsTest
private class PackageVersionCreateActionTest {
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
    private static void multipleRequest() {
        System.runAs(getStandardUser()) {
            // Setup

            Exception expectedException = null;
            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(null, null);

            // Exercise

            try {
                PackageVersionCreateAction.create(new List<PackageVersionCreateAction.Request>{ request, request });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw Exception');
            System.assertEquals(Label.OnlyOneRequestAvailable, expectedException.getMessage(), 'Should throw multiple requests exception.');
        }
    }

    @IsTest
    private static void invalidPackageId() {
        System.runAs(getStandardUser()) {
            // Setup

            Exception expectedException = null;
            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(UserInfo.getUserId(), null);

            // Exercise

            try {
                new PackageVersionCreateAction(request).create();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw Exception');
            System.assertEquals(Label.InvalidPackageId, expectedException.getMessage(), 'Should have Invalid Package Id exception.');
        }
    }

    @IsTest
    private static void withoutJobTemplate() {
        System.runAs(getStandardUser()) {
            // Setup

            Git_Repository__c repo = new Git_Repository__c(Name = 'Repo1');
            insert repo;

            Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('My Pipeline', true, repo.Id, true);
            insert pipeline;

            Artifact__c artifact = new Artifact__c(Pipeline__c = pipeline.Id, Package_Type__c = 'First-Generation Package');
            insert artifact;

            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(artifact.Id, null);

            // Exercise

            Exception expectedException;

            Test.startTest();
            try {
                new PackageVersionCreateAction(request).create();
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
    private static void createVersion() {
        System.runAs(getStandardUser()) {
            // Setup

            Artifact__c artifact = createValidPackageData();
            Artifact_Version__c mockResultRecord = mockPackageVersionRecord(artifact.Name);
            mockResultRecord.Artifact__c = artifact.Id;

            List<PackageVersionCreateAction.Request> requests = new List<PackageVersionCreateAction.Request>{
                new PackageVersionCreateAction.Request(artifact.Id, '{"key": "value"}')
            };

            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(mockResultRecord));

            // Exercise

            Test.startTest();
            PackageVersionCreateAction.Response response = PackageVersionCreateAction.create(requests)[0];
            Test.stopTest();

            // Verify

            Artifact_Version__c version = [
                SELECT
                    Artifact__c,
                    Package_Version_Id__c,
                    Subscriber_Version_Id__c,
                    Is_released__c,
                    Branch__c,
                    Version_Name__c,
                    Tag__c,
                    Version_Description__c,
                    Version_number__c,
                    Data_JSON__c,
                    Name,
                    Artifact__r.Artifact_Version__c
                FROM Artifact_Version__c
            ][0];

            System.assertEquals(mockResultRecord.Artifact__c, version.Artifact__c, 'Artifacts are not the same');
            System.assertEquals(mockResultRecord.Branch__c, version.Branch__c, 'Branch__c are not the same');
            assertData(response, version, mockResultRecord);
        }
    }

    @IsTest
    private static void createVersionWithCallbackAction() {
        System.runAs(getStandardUser()) {
            // Setup

            Artifact__c artifact = createValidPackageData();
            Artifact_Version__c mockResultRecord = mockPackageVersionRecord(artifact.Name);
            mockResultRecord.Artifact__c = artifact.Id;

            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(artifact.Id, '{"key": "value"}');
            request.actionCallback = 'ActionCallbackMock';

            List<PackageVersionCreateAction.Request> requests = new List<PackageVersionCreateAction.Request>{ request };

            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(mockResultRecord));

            // Exercise

            Test.startTest();
            PackageVersionCreateAction.Response response = PackageVersionCreateAction.create(requests)[0];
            Test.stopTest();

            // Verify

            PackageVersionCreateAction.Request requestData = (PackageVersionCreateAction.Request) JSON.deserialize(
                response.job.DataJson__c,
                PackageVersionCreateAction.Request.class
            );
            System.assertNotEquals(null, requestData.actionCallback, 'Action callback parameter is populated');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void updateVersion() {
        System.runAs(getStandardUser()) {
            // Setup

            Artifact__c artifact = createValidPackageData();

            Artifact_Version__c versionRecord = new Artifact_Version__c(Artifact__c = artifact.Id, Branch__c = 'main');
            insert versionRecord;

            Artifact_Version__c mockResultRecord = mockPackageVersionRecord(artifact.Name);
            mockResultRecord.Id = versionRecord.Id;

            List<PackageVersionCreateAction.Request> requests = new List<PackageVersionCreateAction.Request>{
                new PackageVersionCreateAction.Request(artifact.Id, '{"key": "value"}')
            };

            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(mockResultRecord));

            // Exercise

            Test.startTest();
            PackageVersionCreateAction.Response response = PackageVersionCreateAction.create(requests)[0];
            Test.stopTest();

            // Verify

            Artifact_Version__c version = [
                SELECT
                    Artifact__c,
                    Package_Version_Id__c,
                    Subscriber_Version_Id__c,
                    Is_released__c,
                    Branch__c,
                    Version_Name__c,
                    Tag__c,
                    Version_Description__c,
                    Version_number__c,
                    Data_JSON__c,
                    Name,
                    Artifact__r.Artifact_Version__c
                FROM Artifact_Version__c
            ][0];

            assertData(response, version, mockResultRecord);
        }
    }

    private static Artifact__c createValidPackageData() {
        JobTemplate__c template = new JobTemplate__c(Name = 'TestVersionCreate', Version__c = 1);
        insert template;

        JobStep__c step = new JobStep__c(JobTemplate__c = template.Id, Type__c = 'Flow', ConfigJson__c = '{"flowName" : "MockedFlow"}');
        insert step;

        MultiCloudAutomationsSelector.mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>{
            'Other' => new List<MultiCloudAutomation__mdt>{
                new MultiCloudAutomation__mdt(
                    MasterLabel = 'CreatePackageVersionAction',
                    DeveloperName = 'CreatePackageVersionAction',
                    Action__c = 'CreatePackageVersion',
                    Job_Template__c = 'TestVersionCreate_1'
                )
            }
        };

        NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
            new MC_Notification__mdt(
                DeveloperName = 'Generate_Package_Version_Success',
                Active__c = true,
                Subject__c = 'Package Version {PackageName} - {PackageVersionName} was generated successfully',
                Template__c = 'Hi {UserName}, <br/><br/> Package Version <b><a href="{PackageVersionLink}">{PackageVersionName}</a></b> was successfully generated.'
            )
        };

        Git_Repository__c repo = new Git_Repository__c(Name = 'Repo1');
        insert repo;

        Deployment_Flow__c pipeline = new Deployment_Flow__c(Name = 'Other', Platform__c = 'Other', Git_Repository__c = repo.Id);
        insert pipeline;

        Artifact__c artifact = new Artifact__c(Pipeline__c = pipeline.Id, Package_Type__c = 'First-Generation Package');
        insert artifact;

        return artifact;
    }

    private static void assertData(PackageVersionCreateAction.Response response, Artifact_Version__c version, Artifact_Version__c mockResultRecord) {
        System.assertEquals('Successful', response.job.Status__c, 'Job execution status should be Successful');
        System.assertEquals(mockResultRecord.Package_Version_Id__c, version.Package_Version_Id__c, 'Package_Version_Id__c are not the same');
        System.assertEquals(mockResultRecord.Is_released__c, version.Is_released__c, 'Is_released__c are not the same');
        System.assertEquals(mockResultRecord.Version_Name__c, version.Version_Name__c, 'Version_Name__c are not the same');
        System.assertEquals(mockResultRecord.Version_number__c, version.Version_number__c, 'Version_number__c are not the same');
        System.assertEquals(mockResultRecord.Data_JSON__c, version.Data_JSON__c, 'Data_JSON__c are not the same');
        System.assertEquals(mockResultRecord.Name, version.Name, 'Name are not the same');
        System.assertEquals(version.Id, version.Artifact__r.Artifact_Version__c, 'Latest package version is not updated');

        List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
        System.assertEquals(1, events.size(), 'An Automation Event should be created');
        System.assertEquals(ActionConstants.CREATE_PACKAGE_VERSION, events[0].Action_Name__c, 'Action Name should match');
    }

    // HELPER

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = JSON.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static Artifact_Version__c mockPackageVersionRecord(String packageName) {
        Artifact_Version__c result = new Artifact_Version__c();
        result.Package_Version_Id__c = '05i7Q000000blPMQAY';
        result.Subscriber_Version_Id__c = '04t7Q00000090xtQAA';
        result.Is_released__c = false;
        result.Branch__c = 'main';
        result.Version_Name__c = 'My Version';
        result.Tag__c = null;
        result.Version_Description__c = null;
        result.Version_number__c = '1.0.0.0';
        result.Data_JSON__c = '{\"uninstallscript\":\"\",\"postinstallscript\":\"\",\"postinstallurl\":\"\",\"releasenotesurl\":\"\",\"skipvalidation\":true,\"codecoverage\":false,\"installationkeybypass\":true,\"tag\":\"\",\"overrideProjectJsonPath\":null,\"overridePath\":null,\"apiversion\":\"45.0\"}';
        result.Name = packageName + ' - 1.0.0.0';

        return result;
    }

    private static User getStandardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}