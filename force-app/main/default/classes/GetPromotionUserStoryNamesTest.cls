@IsTest
private class GetPromotionUserStoryNamesTest {
    private static User RUNNING_USER;

    static {
    }

    @TestSetup
    private static void setup() {
        RUNNING_USER = TestDataFactory.createUsers()[0];
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        assignPermissions(RUNNING_USER.Id);
    }

    @IsTest
    private static void executeInvocable() {
        // Setup

        RUNNING_USER = user();
        TestUtilities.assignLicense(RUNNING_USER.Username, true, true, true, true, true, true);

        System.runAs(RUNNING_USER) {
            insertTestData();
        }

        Deployment_Job__c job = [SELECT Step__r.Deployment__r.Promotion__c FROM Deployment_Job__c LIMIT 1];
        GetPromotionUserStoryNames.InvocableVariables variables = new GetPromotionUserStoryNames.InvocableVariables();
        variables.promotionId = job.Step__r.Deployment__r.Promotion__c;
        variables.jobId = job.Id;

        // Exercise

        List<String> result;
        System.runAs(RUNNING_USER) {
            Test.startTest();
            result = GetPromotionUserStoryNames.execute(new List<GetPromotionUserStoryNames.InvocableVariables>{ variables });
            Test.stopTest();
        }

        // Verify

        System.assert(!result.isEmpty(), 'List returned by data collector is empty.');
    }

    @IsTest
    private static void executeFlow() {
        // Setup

        RUNNING_USER = user();
        TestUtilities.assignLicense(RUNNING_USER.Username, true, true, true, true, true, true);

        System.runAs(RUNNING_USER) {
            insertTestData();
        }

        Deployment_Job__c job = [SELECT Step__c FROM Deployment_Job__c LIMIT 1];

        // Exercise

        System.runAs(RUNNING_USER) {
            Test.startTest();
            new Flow.Interview.Get_Promotion_User_Story_Names(new Map<String, Object>{ 'jobId' => job.Id }).start();
            Test.stopTest();
        }

        // Verify

        Step__c step = [SELECT JsonResult__c FROM Step__c WHERE Id = :job.Step__c];
        System.assert(String.isNotBlank(step.JsonResult__c), 'JSON Result was not properly set by the flow.');
    }

    // Helper

    private static User user() {
        return [SELECT Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
    }

    private static void assignPermissions(Id userId) {
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    private static void insertTestData() {
        List<Environment__c> environments = new List<Environment__c>();
        Environment__c dev1Environment = CMTestMethodUtilities.createEnvironment('DEV-1', '000000000000000001');
        environments.add(dev1Environment);
        Environment__c intEnvironment = CMTestMethodUtilities.createEnvironment('INT', '000000000000000002');
        environments.add(intEnvironment);
        insert environments;

        List<Org__c> orgs = new List<Org__c>();
        Org__c userCredential = CMTestMethodUtilities.createOrg(
            'USER-ORG',
            'Production',
            Userinfo.getOrganizationId() +
            '_' +
            Userinfo.getUserId(),
            null,
            UserInfo.getUserName(),
            System.now(),
            null
        );
        userCredential.Oauth_Signature__c = '111222333444';
        orgs.add(userCredential);
        Org__c dev1Credential = CMTestMethodUtilities.createOrg(
            'DEV-1',
            'Production',
            '000000000000000001',
            null,
            null,
            System.now(),
            dev1Environment.Id
        );
        orgs.add(dev1Credential);
        Org__c intCredential = CMTestMethodUtilities.createOrg(
            'INT',
            'Production',
            '000000000000000002',
            null,
            null,
            System.now(),
            intEnvironment.Id
        );
        orgs.add(intCredential);
        insert orgs;

        Deployment_Flow__c pipeline = CMTestMethodUtilities.createFlow('PIPELINE');
        pipeline.Active__c = true;
        pipeline.Platform__c = 'Salesforce';
        insert pipeline;

        Deployment_Flow_Step__c pipelineConnection = CMTestMethodUtilities.createFlowStep(dev1Environment.Id, intEnvironment.Id, pipeline.Id);
        insert pipelineConnection;

        Project__c project = CMTestMethodUtilities.createProject('PROJECT');
        project.Deployment_Flow__c = pipeline.Id;
        insert project;

        Promotion__c promotion = CMTestMethodUtilities.createPromotion(project.Id, dev1Environment.Id);
        promotion.Source_Org_Credential__c = dev1Credential.Id;
        insert promotion;

        User_Story__c story = new User_Story__c(User_Story_Title__c = 'USER STORY', Org_Credential__c = dev1Credential.Id, Project__c = project.Id);
        insert story;

        insert new Promoted_User_Story__c(User_Story__c = story.Id, Promotion__c = promotion.Id);

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT', Datetime.now(), Datetime.now(), dev1Credential.Id, null, 'In progress');
        deployment.Promotion__c = promotion.Id;
        insert deployment;

        Step__c step = testMethodUtilities.create(
            'STEP',
            null,
            '[{"name": "LogLevel", "value": "ERROR"}]',
            deployment.Id,
            0,
            'In progress',
            'Salesforce Flow'
        );
        insert step;

        Destination_Org__c destination = testMethodUtilities.create(deployment.Id, 'In progress', intCredential.Id);
        insert destination;

        Deployment_Job__c job = testMethodUtilities.create(1, destination.Id, null, 'In progress', step.Id);
        insert job;
    }
}