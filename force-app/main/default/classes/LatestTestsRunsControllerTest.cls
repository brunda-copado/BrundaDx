@SuppressWarnings('PMD.CyclomaticComplexity')
@isTest
private class LatestTestsRunsControllerTest {

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @isTest
    private static void getTests() {
        System.runAs(getRunAsUser()) {
            //Setup
            insertMockTestTool();
            Promotion__c promotion = createPromotion();

            // Exercise
            Test.startTest();
            List<LatestTestsRunsController.TestWrapper> tests = LatestTestsRunsController.getTests(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, tests.size(), 'There should be 1 test for user story.');
        }
    }

    @IsTest
    private static void getTestsForBeforeQualityGate() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertMockTestTool();
            Promotion__c promotion = createPromotion();
            createDeploymentAndRelatedRecords(promotion.Id);

            // Exercise
            List<LatestTestsRunsController.TestWrapper> tests = LatestTestsRunsController.getTests(promotion.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'There should be 1 test for promotion.');
        }
    }

    private static void createData() {
        new JobTemplate().name('MockTemplate').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(
                new Project()
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();

        ExtensionConfiguration__c extConfig = createExtensionConfiguration();

        Test__c userStoryTest = new Test__c(
            Name = 'User Story Test',
            ExtensionConfiguration__c = extConfig.Id,
            ReadyToRun__c = true,
            User_Story__c = getUserStory().Id
        );

        insert new List<Test__c>{ userStoryTest };
    }

    private static void createRelatedResults(Id parentId, Id promotionId) {
        List<Result__c> results = new List<Result__c>();
        List<Test__c> tests = new TestsSelector().byParentAndAutomaticallyExecutableTests(parentId);

        for (Test__c test : tests) {
            results.add(testMethodUtilities.createResult(test.Id));
        }
        insert results;

        JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
            .promotion(promotionId)
            .dataJson('{ "promotionId" : "' + promotionId + '", "testIds" : [ "' + tests[0].Id + '" ]}')
            .persist();
        tests[0].LatestJobExecution__c = jobExecution.Id;
        update tests;
    }

    private static Promotion__c createPromotion() {
        User_Story__c userStory = getUserStory();
        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId(getProject().Id)
            .sourceEnvId(getEnvironment('dev1').Id)
            .add(new PromotedUserStory().userStory(userStory.Id))
            .persist();

        createRelatedResults(userStory.Id, promotion.Id);
        return promotion;
    }

    private static void createDeploymentAndRelatedRecords(Id promotionId) {
        Deployment__c deployment = (Deployment__c) new Deployment().Name('Test Deployment').promotion(promotionId).persist();
        User_Story__c userStory = getUserStory();
        List<Test__c> tests = new TestsSelector().byParentAndAutomaticallyExecutableTests(userStory.Id);

        JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
            .deployment(deployment.Id)
            .dataJson('{ "promotionId" : "' + promotionId + '", "deploymentId" : "' + deployment.Id + '", "testIds" : [ "' + tests[0].Id + '" ]}')
            .persist();
        tests[0].LatestJobExecution__c = jobExecution.Id;
        update tests;

        Quality_Gate_Rule__c qualityGateRule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action('PromotionDeployment')
            .sequence('Before')
            .tool('None')
            .active(false)
            .add(
                new QualityGateRuleCondition()
                    .platform('Other')
                    .environment(new Environment().platform('Other'))
                    .extensionConfiguration(getMockExtensionConfiguration().id)
            )
            .persist();

        qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
        update qualityGateRule;

        // Create Test Job Step
        JobStep__c jobStep = new JobStep__c(
            Type__c = 'Test',
            CustomType__c = 'Test',
            Name = 'Quality Gate Test Step',
            ExecutionSequence__c = 'before',
            JobTemplate__c = getJobTemplate().Id,
            JobExecution__c = jobExecution.Id,
            Quality_Gate_Rule__c = qualityGateRule.Id
        );
        insert jobStep;

        Result__c result = new Result__c(Job_Type__c = 'Manual Tests', JobStep__c = jobStep.id);
        insert result;

        jobStep.Result__c = result.Id;
        update jobStep;

        jobExecution.Job_Step__c = jobStep.Id;
        update jobExecution;
    }

    private static ExtensionConfiguration__c getMockExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c WHERE ExtensionTool__c = :'Manual Tests' LIMIT 1];
    }

    private static Project__c getProject() {
        return [SELECT Id FROM Project__c LIMIT 1];
    }

    private static Environment__c getEnvironment(String envName) {
        return [SELECT Id FROM Environment__c WHERE Name = :envName LIMIT 1];
    }

    private static JobTemplate__c getJobTemplate() {
        return [SELECT Id FROM JobTemplate__c LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static void insertMockTestTool() {
        String jobTemplateApiName = 'MockTemplate_1';
        TestToolsSelector.mock(
            new List<TestTool__mdt>{
                new TestTool__mdt(
                    MasterLabel = 'None',
                    JobTemplate__c = jobTemplateApiName,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                ),
                new TestTool__mdt(
                    MasterLabel = 'Manual Tests',
                    JobTemplate__c = jobTemplateApiName,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                )
            }
        );
    }

    private static ExtensionConfiguration__c createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        return extensionConfig;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}