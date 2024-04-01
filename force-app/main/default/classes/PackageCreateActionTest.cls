@IsTest
private class PackageCreateActionTest {
    @TestSetup
    private static void createData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        new User_t().admin().assign(new PermissionSetAssignment_t().copadoUser());
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
            PackageCreateAction.Request request = new PackageCreateAction.Request(null, null);

            // Exercise

            try {
                PackageCreateAction.create(new List<PackageCreateAction.Request>{ request, request });
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
            PackageCreateAction.Request request = new PackageCreateAction.Request(null, null);

            // Exercise

            try {
                new PackageCreateAction(request).create();
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

            DataHelper helper = new DataHelper().createRepository('Repo1').createPipeline('My Pipeline', 'Other').createPackage();
            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, null);

            // Exercise

            Exception expectedException;

            Test.startTest();
            try {
                new PackageCreateAction(request).create();
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
    private static void invalidJSON() {
        System.runAs(getStandardUser()) {
            // Setup
            Exception expectedException = null;

            DataHelper helper = new DataHelper().createRepository('Repo1').createPipeline('My Pipeline', 'Other').createPackage();

            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, '{"key": "value",}');

            // Exercise

            try {
                PackageCreateAction.create(new List<PackageCreateAction.Request>{ request });
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
    private static void pipelineNotFound() {
        System.runAs(getStandardUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().mockAutomations().createPackage().createTemplate();

            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, '{"key": "value"}');

            // Exercise

            try {
                PackageCreateAction.create(new List<PackageCreateAction.Request>{ request });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assertEquals(Label.NoPipelineLinkedToPackage, expectedException.getMessage(), 'Should throw invalid pipeline exception.');
        }
    }

    @IsTest
    private static void repositoryNotLinked() {
        System.runAs(getStandardUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().mockAutomations().createTemplate().createPipeline('Other', 'Other').createPackage();

            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, '{"key": "value"}');

            // Exercise

            try {
                PackageCreateAction.create(new List<PackageCreateAction.Request>{ request });
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
    private static void licensesNotAssigned() {
        System.runAs(getAdminUser()) {
            // Setup
            Exception expectedException = null;

            // Exercise

            try {
                PackageCreateAction.create(new List<PackageCreateAction.Request>{ new PackageCreateAction.Request(null, null) });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent');
            System.assertNotEquals(null, expectedException, 'Should throw exception.');
            System.assertEquals(Label.LicensesNotAssigned, expectedException.getMessage(), 'Should throw licence not assigned exception.');
        }
    }

    @IsTest
    private static void createPackage() {
        System.runAs(getStandardUser()) {
            // Setup

            DataHelper helper = new DataHelper()
                .mockAutomations()
                .createTemplate()
                .createRepository('Repo1')
                .createPipeline('Other', 'Other')
                .createPackage();

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Create_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {package_name} was created successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b><a href="{PackageLink}">{PackageName}</a></b> was successfully created.'
                )
            };

            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, '{"key": "value"}');

            List<PackageCreateAction.Request> requests = new List<PackageCreateAction.Request>{ request };

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise

            PackageCreateAction.create(requests);

            // Verify

            List<JobExecution__c> jobs = [SELECT DataJson__c FROM JobExecution__c];
            System.assertEquals(1, jobs.size(), 'Job execution should be started.');
            System.assertEquals(JSON.serialize(requests[0]), jobs[0].DataJson__c, 'Payload should be passed to job execution.');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.CREATE_PACKAGE, events[0].Action_Name__c, 'Action Name should match');

            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        }
    }

    @IsTest
    private static void createPackageWithActionCallback() {
        System.runAs(getStandardUser()) {
            // Setup

            DataHelper helper = new DataHelper()
                .mockAutomations()
                .createTemplate()
                .createRepository('Repo1')
                .createPipeline('Other', 'Other')
                .createPackage();

            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Create_Package_Success',
                    Active__c = true,
                    Subject__c = 'Package {package_name} was created successfully',
                    Template__c = 'Hi {UserName}, <br/><br/> Package <b><a href="{PackageLink}">{PackageName}</a></b> was successfully created.'
                )
            };

            PackageCreateAction.Request request = new PackageCreateAction.Request(helper.artifact.Id, '{"key": "value"}');
            request.actionCallback = 'ActionCallbackMock';

            List<PackageCreateAction.Request> requests = new List<PackageCreateAction.Request>{ request };

            // Exercise

            List<PackageCreateAction.Response> response = PackageCreateAction.create(requests);

            // Verify

            PackageCreateAction.Request requestData = (PackageCreateAction.Request) JSON.deserialize(
                response.get(0).job.DataJson__c,
                PackageCreateAction.Request.class
            );
            System.assertNotEquals(null, requestData.actionCallback, 'Action callback parameter is populated');
        }
    }

    // HELPER

    private class DataHelper {
        private Git_Repository__c repository;
        private Deployment_Flow__c pipeline;
        private Artifact__c artifact;
        private JobTemplate__c template;

        private DataHelper mockAutomations() {
            MultiCloudAutomationsSelector.mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>{
                'Other' => new List<MultiCloudAutomation__mdt>{
                    new MultiCloudAutomation__mdt(
                        MasterLabel = 'CreatePackageAction',
                        DeveloperName = 'CreatePackageAction',
                        Action__c = 'CreatePackage',
                        Job_Template__c = 'TestVersionCreate_1'
                    )
                }
            };
            return this;
        }

        private DataHelper createRepository(String name) {
            repository = new Git_Repository__c(Name = name);
            insert repository;

            return this;
        }

        private DataHelper createPipeline(String name, String platform) {
            pipeline = new Deployment_Flow__c(Name = name, Platform__c = platform, Git_Repository__c = repository?.Id);
            insert pipeline;

            return this;
        }

        private DataHelper createPackage() {
            artifact = new Artifact__c(Pipeline__c = pipeline?.Id, Package_Type__c = 'First-Generation Package');
            insert artifact;

            return this;
        }

        private DataHelper createTemplate() {
            template = new JobTemplate__c(Name = 'TestVersionCreate', Version__c = 1);
            insert template;

            JobStep__c step = new JobStep__c(Name = 'Step1', Type__c = 'Flow', JobTemplate__c = template.Id);
            insert step;

            return this;
        }
    }

    private static User getStandardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getAdminUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}