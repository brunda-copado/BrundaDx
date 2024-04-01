@isTest
private class OpenPullRequestTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getData() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = createPromotion('dev1', 'dev2');

            Test.startTest();
            OpenPullRequestController.Response response = OpenPullRequestController.getData(promotion.Id);
            Test.stopTest();

            System.assertNotEquals(null, response.promotion, 'Promotion information should be retrieved');
            System.assertNotEquals(null, response.pipeline, 'Pipeline information should be retrieved');
            System.assertEquals('dev2', response.destinationEnvironmentBranch, 'Destination branch should be retrieved');
            System.assertEquals(false, response.isMerged, 'Merge information should be retrieved');
        }
    }

    @IsTest
    private static void destinationBranchFromPipeline() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = createPromotion('dev2', 'prod');

            Test.startTest();
            OpenPullRequestController.Response response = OpenPullRequestController.getData(promotion.Id);
            Test.stopTest();

            System.assertNotEquals(null, response.promotion, 'Promotion information should be retrieved');
            System.assertNotEquals(null, response.pipeline, 'Pipeline information should be retrieved');
            System.assertEquals('main', response.destinationEnvironmentBranch, 'Destination branch should be retrieved');
            System.assertEquals(false, response.isMerged, 'Merge information should be retrieved');
        }
    }

    private static void createData() {
        new JobTemplate().name('JOB_TEMPLATE_PROMOTION').mockAutomation(ActionConstants.PROMOTION).add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').platform('Other').add(new Credential());

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, dev2).branch('dev1'))
            .add(new Connection(dev2, prod).branch('dev2'))
            .add(new Project().add(new UserStory().credential(dev1Credential)))
            .persist();

        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
    }

    private static Promotion__c createPromotion(String sourceEnvName, String destinationEnvName) {
        Promotion__c firstPromotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = :sourceEnvName LIMIT 1].Id)
            .destinationEnvId([SELECT Id FROM Environment__c WHERE Name = :destinationEnvName LIMIT 1].Id)
            .persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
            User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1]
            .Id,
            Promotion__c = firstPromotion.Id
        );
        insert promotedUserStory;
        return firstPromotion;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}