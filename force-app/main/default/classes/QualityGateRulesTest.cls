@IsTest
private with sharing class QualityGateRulesTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
    private static final String MOCK_TYPE = 'Mock Type';

    @TestSetup
    static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void setTestToolTypeOnCreate() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = MOCK_TYPE) });
            Quality_Gate_Rule__c record = qualityGateRule(ActionConstants.PROMOTION);

            // Exercise
            Test.startTest();
            insert record;
            Test.stopTest();

            // Verify
            System.assertEquals(
                MOCK_TYPE,
                new QualityGateRulesSelector().byId(record.Id).Type__c,
                'Incorrect Test Type assigned for selected Test Tool.'
            );
        }
    }

    @IsTest
    static void setTestToolTypeWithMissingToolOnCreate() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());

            // Exercise
            String errorMessage;

            Test.startTest();
            try {
                insert qualityGateRule(ActionConstants.PROMOTION);
            } catch (Exception error) {
                errorMessage = error.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assert(
                errorMessage.contains(Label.Test_Tool_does_not_Exist),
                'Users should not be able to create quality gate rules when the selected tool is not available.'
            );
        }
    }

    @IsTest
    static void validateForbiddenActions() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = MOCK_TYPE) });

            // Exercise
            Exception validationException;

            Test.startTest();
            try {
                insert qualityGateRule(String.join(new List<String>{ ActionConstants.PROMOTION, ActionConstants.CREATE_PACKAGE }, ';'));
            } catch (Exception error) {
                validationException = error;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationException, 'There should be an exception thrown');
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, validationException.getDmlType(0), 'Exception type does not match.');
        }
    }

    @IsTest
    static void createAutomationsOnActivation() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = MOCK_TYPE) });
            new QualityGateRule()
                .action(ActionConstants.PROMOTION)
                .sequence(QualityGateConstants.AFTER)
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(getExtensionConfiguration().Id)
                )
                .persist();

            // Exercise
            Test.startTest();
            Quality_Gate_Rule__c qualityGateRule = [SELECT Id FROM Quality_Gate_Rule__c LIMIT 1];
            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;

            update qualityGateRule;
            Test.stopTest();

            // Verify
            Automation_Rule__c automationRule = [
                SELECT Id, Active__c
                FROM Automation_Rule__c
                WHERE Quality_Gate_Rule_Condition__r.Quality_Gate_Rule__c = :qualityGateRule.Id
                LIMIT 1
            ];
            System.assertEquals(true, automationRule.Active__c, 'An active automation rule should be created.');
        }
    }

    @IsTest
    static void deleteAutomationsOnDeactivation() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = MOCK_TYPE) });
            new QualityGateRule()
                .action(ActionConstants.PROMOTION)
                .sequence(QualityGateConstants.AFTER)
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(getExtensionConfiguration().Id)
                )
                .persist();

            Quality_Gate_Rule__c qualityGateRule = [SELECT Id FROM Quality_Gate_Rule__c LIMIT 1];
            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
            update qualityGateRule;

            // Exercise
            Test.startTest();
            qualityGateRule.Status__c = QualityGateConstants.INACTIVE;

            update qualityGateRule;
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> automationRules = [
                SELECT Id
                FROM Automation_Rule__c
                WHERE Quality_Gate_Rule_Condition__r.Quality_Gate_Rule__c = :qualityGateRule.Id
                ORDER BY Source_Action__c
            ];

            System.assertEquals(0, automationRules.size(), 'Automation Rule should be deleted.');
        }
    }

    // HELPER

    private static void createData() {
        createExtensionConfiguration();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(
                new Project()
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }

    static Quality_Gate_Rule__c qualityGateRule(String actions) {
        return new Quality_Gate_Rule__c(
            Name = 'None Test',
            Tool__c = NONE_VALUE,
            Status__c = 'Active',
            Actions__c = actions,
            Execution_sequence__c = 'Before'
        );
    }

    static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(Name = 'EC 1', ExtensionApplication__c = 'Test', ExtensionTool__c = 'Manual Tests', Active__c = true);
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }
}