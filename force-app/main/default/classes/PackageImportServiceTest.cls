@IsTest
public class PackageImportServiceTest {
    @TestSetup
    public static void makeData() {
        new DataHelper().userSetup();
    }

    @IsTest
    public static void run() {
        System.runAs(getRunAsUser()) {
            // Setup

            DataHelper helper = new DataHelper().createJobTemplate().mockDefaultTemplates().createRepository().createPipeline().createRequest();

            // Exercise

            String result = new PackageImportService().run(helper.request);
            PackageImportService.Response response = (PackageImportService.Response) JSON.deserialize(result, PackageImportService.Response.class);

            // Verify

            System.assertEquals('OK', response.status, 'Status should be OK.');
            System.assertEquals('Package import started successfully.', response.message, 'Package import should have started successfully.');
            System.assertNotEquals(null, response.body.job, 'Job execution should be started.');
        }
    }

    @IsTest
    public static void failure() {
        System.runAs(getRunAsUser()) {
            // Setup

            Exception expectedException = null;
            DataHelper helper = new DataHelper().createRequest();

            // Exercise
            try {
                new PackageImportService().run(helper.request);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'Exception should be thrown.');
        }
    }

    // Helper

    private class DataHelper {
        private Git_Repository__c repository;
        private Deployment_Flow__c pipeline;
        private JobTemplate__c template;
        private CliProxy.CLIWrapper request;

        private DataHelper createRepository() {
            repository = TestDataFactory.createGitRepository();
            insert repository;

            return this;
        }

        private DataHelper createPipeline() {
            pipeline = TestDataFactory.createDeploymentFlow('Test Pipeline', true, repository.Id, true);
            pipeline.Platform__c = 'Other';
            insert pipeline;

            return this;
        }

        private DataHelper createJobTemplate() {
            template = new JobTemplate__c(Name = 'PackageImportTemplate', Version__c = 1);
            insert template;

            JobStep__c step = new JobStep__c(Name = 'Step1', Type__c = 'Manual', JobTemplate__c = template.Id);
            insert step;

            return this;
        }

        private DataHelper mockDefaultTemplates() {
            MultiCloudAutomationsSelector.mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>{
                'Other' => new List<MultiCloudAutomation__mdt>{
                    new MultiCloudAutomation__mdt(
                        MasterLabel = 'ImportPackageAction',
                        DeveloperName = 'ImportPackageAction',
                        Action__c = 'ImportPackage',
                        Job_Template__c = 'PackageImportTemplate_1'
                    )
                }
            };

            return this;
        }

        private DataHelper createRequest() {
            request = new CliProxy.CLIWrapper();
            request.mainService = 'package';
            request.subService = 'import';
            request.body = JSON.serialize(new PackageImportAction.Request('Testpkg', pipeline?.Id, null));

            return this;
        }

        private void userSetup() {
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

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}