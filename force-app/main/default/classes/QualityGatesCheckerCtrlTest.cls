@IsTest
private with sharing class QualityGatesCheckerCtrlTest {
    private static final String TEST_TOOL_NAME = 'Manual Tests';
    private static final String MOCK_ACTION_CALLBACK = 'MockRunTestsActionCallback';
    private static final String MOCK_ACCEPTANCE_CRITERIA = '{"criteria1": "mockCriteria1", "criteria2": "mockCriteria2"}';

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void checkQualityGates() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = getPromotion();

            // Exercise
            Test.startTest();
            QualityGatesCheckerCtrl.QualityGatesCheckResult result = QualityGatesCheckerCtrl.checkQualityGates(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(0, result.qualityGateRules.size(), 'No Quality Gate should be returned');
        }
    }

    @IsTest
    private static void deactivateQualityGates() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Quality_Gate_Rule__c> rules = [SELECT Id, Status__c FROM Quality_Gate_Rule__c];

            // Exercise
            Test.startTest();
            QualityGatesCheckerCtrl.deactivateQualityGates(rules);
            Test.stopTest();

            // Verify
            Integer automationRules = [SELECT COUNT() FROM Automation_Rule__c];
            System.assertEquals(0, automationRules, 'No Automation Rules should left');
        }
    }

    @IsTest
    private static void activateQualityGates() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Quality_Gate_Rule__c> rules = [SELECT Id, Status__c FROM Quality_Gate_Rule__c];
            
            // Exercise
            Test.startTest();
            QualityGatesCheckerCtrl.deactivateQualityGates(rules);
            QualityGatesCheckerCtrl.activateQualityGates(rules);
            Test.stopTest();

            // Verify
            Integer automationRules = [SELECT COUNT() FROM Automation_Rule__c];
            System.assertEquals(1, automationRules, '1 Automation Rules should be created');
        }
    }

    // PRIVATE

    private static void createData() {
        createExtensionConfiguration();

        new JobTemplate().name('MockTemplate').mockAutomation(ActionConstants.RUN_QG).add(new JobStep());
        new JobTemplate().name('Promotion_Deployment_Template').mockAutomation(ActionConstants.PROMOTION_DEPLOYMENT).add(new JobStep()).persist();

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
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();

        User_Story__c userStory = getUserStory('US1');
        Promotion__c promotion = (Promotion__c) new Promotion().projectId([SELECT Id FROM Project__c LIMIT 1].Id).sourceEnvId(dev1.Id).persist();
        insert new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);

        ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();

        List<Test__c> tests = new List<Test__c>();
        Test__c test1 = new Test__c(
            Name = 't1',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory.Id,
            ReadyToRun__c = true
        );
        Test__c test2 = new Test__c(
            Name = 't2',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory.Id,
            ReadyToRun__c = true
        );
        tests.add(test1);
        tests.add(test2);

        insert tests;

        createMockTestTools();
        createQualityGate();
    }

    private static void createMockTestTools() {
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
                    MasterLabel = TEST_TOOL_NAME,
                    JobTemplate__c = jobTemplateApiName,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                )
            }
        );
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(
            Name = 'EC 1',
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            AcceptanceCriteria__c = MOCK_ACCEPTANCE_CRITERIA,
            Active__c = true
        );
    }

    private static void createQualityGate() {
        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action(ActionConstants.PROMOTION_DEPLOYMENT)
            .sequence(QualityGateConstants.AFTER)
            .tool('None')
            .active(false)
            .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(getExtensionConfiguration().Id))
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static Promotion__c getPromotion() {
        return [SELECT Id FROM Promotion__c LIMIT 1];
    }

    private static User_Story__c getUserStory(String userStoryTitle) {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :userStoryTitle LIMIT 1];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}