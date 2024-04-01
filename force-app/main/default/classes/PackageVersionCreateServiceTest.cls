@IsTest
private class PackageVersionCreateServiceTest {
    @IsTest
    private static void failure() {
        // Setup

        Exception expectedException = null;
        PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(UserInfo.getUserId(), null);

        CliProxy.CLIWrapper cliRequest = new CliProxy.CLIWrapper();
        cliRequest.body = JSON.serialize(request);

        // Exercise

        try {
            System.runAs(getStandardUser()) {
                new PackageImportService().run(cliRequest);
            }
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify

        System.assertNotEquals(null, expectedException, 'Should throw Exception.');
    }

    @IsTest
    private static void run() {
        System.runAs(getStandardUser()) {
            // Setup

            JobTemplate__c template = new JobTemplate__c(Name = 'TestVersionCreate', Version__c = 1);
            insert template;

            JobStep__c step = new JobStep__c(Name = 'Step1', Type__c = 'Manual', JobTemplate__c = template.Id);
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

            Git_Repository__c repo = new Git_Repository__c(Name = 'Repo1');
            insert repo;

            Deployment_Flow__c pipeline = new Deployment_Flow__c(Name = 'Other', Platform__c = 'Other', Git_Repository__c = repo.Id);
            insert pipeline;

            Artifact__c artifact = new Artifact__c(Pipeline__c = pipeline.Id, Package_Type__c = 'First-Generation Package');
            insert artifact;

            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(artifact.Id, '{"key": "value"}');

            CliProxy.CLIWrapper cliRequest = new CliProxy.CLIWrapper();
            cliRequest.body = JSON.serialize(request);

            // Exercise

            String result = new PackageVersionCreateService().run(cliRequest);
            PackageVersionCreateService.Response response = (PackageVersionCreateService.Response) JSON.deserialize(
                result,
                PackageVersionCreateService.Response.class
            );

            // Verify

            List<JobExecution__c> jobs = [SELECT Id FROM JobExecution__c];

            System.assertEquals('OK', response.status, 'Status should be OK.');
            System.assertEquals(1, jobs.size(), 'Job execution should be started.');
        }
    }

    // HELPER

    private static User getStandardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    @TestSetup
    private static void createData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableCopado().persist();
        }
    }
}