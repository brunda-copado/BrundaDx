@IsTest
private class SetDefaultAutomationTemplateTest {
    /* @TestSetup
    private static void setupData() {
        createTemplates();
    }

    @IsTest
    private static void execute() {
        // Setup
        MultiCloudAutomationsSelector.mock = new Map<String, MultiCloudAutomation__mdt>{
            'Other' => new MultiCloudAutomation__mdt(
                PlatformName__c = 'Other',
                DeployAPIName__c = 'DeployTemplate_1',
                PromoteAPIName__c = 'PromoteTemplate_1'
            )
        };

        // Exercise
        User copadoUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        Deployment_Flow__c pipeline;

        System.runAs(copadoUser) {
            pipeline = new Deployment_Flow__c(Name = 'Other', Platform__c = 'Other');
            insert pipeline;
        }

        // Verify
        Deployment_Flow__c result = [
            SELECT Id, Promotion_Job_Template__r.ApiName__c, Deployment_Job_Template__r.ApiName__c
            FROM Deployment_Flow__c
            WHERE Id = :pipeline.Id
        ];

        System.assertEquals('PromoteTemplate_1', result.Promotion_Job_Template__r.ApiName__c);
        System.assertEquals('DeployTemplate_1', result.Deployment_Job_Template__r.ApiName__c);
    }

    @IsTest
    private static void executeWithUserInput() {
        // Setup
        MultiCloudAutomationsSelector.mock = new Map<String, MultiCloudAutomation__mdt>{
            'Other' => new MultiCloudAutomation__mdt(
                PlatformName__c = 'Other',
                DeployAPIName__c = 'DeployTemplate_1',
                PromoteAPIName__c = 'PromoteTemplate_1'
            )
        };

        // Exercise
        User copadoUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        JobTemplate__c promoteTemplate2 = [SELECT Id FROM JobTemplate__c WHERE ApiName__c = 'PromoteTemplate_2'];
        JobTemplate__c deploymentTemplate2 = [SELECT Id FROM JobTemplate__c WHERE ApiName__c = 'DeployTemplate_2'];
        Deployment_Flow__c pipeline;

        System.runAs(copadoUser) {
            pipeline = new Deployment_Flow__c();
            pipeline.Name = 'Other';
            pipeline.Platform__c = 'Other';
            pipeline.Promotion_Job_Template__c = promoteTemplate2.Id;
            pipeline.Deployment_Job_Template__c = deploymentTemplate2.Id;
            insert pipeline;
        }

        // Verify
        Deployment_Flow__c result = [
            SELECT Id, Promotion_Job_Template__r.ApiName__c, Deployment_Job_Template__r.ApiName__c
            FROM Deployment_Flow__c
            WHERE Id = :pipeline.Id
        ];

        System.assertEquals('PromoteTemplate_2', result.Promotion_Job_Template__r.ApiName__c);
        System.assertEquals('DeployTemplate_2', result.Deployment_Job_Template__r.ApiName__c);
    }

    // HELPER

    private static void createTemplates() {
        User user = TestDataFactory.createUsers()[0];
        User copadoUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Job_Engine')]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = ps.Id));
        }

        insert assignments;

        System.runAs(copadoUser) {
            TestUtilities.assignLicense(String.valueOf(copadoUser.Username), true, true, true, true, true);

            List<JobTemplate__c> templates = new List<JobTemplate__c>{
                new JobTemplate__c(Name = 'DeployTemplate', Version__c = 1),
                new JobTemplate__c(Name = 'DeployTemplate', Version__c = 2),
                new JobTemplate__c(Name = 'PromoteTemplate', Version__c = 1),
                new JobTemplate__c(Name = 'PromoteTemplate', Version__c = 2)
            };

            insert templates;
        }
    } */
}