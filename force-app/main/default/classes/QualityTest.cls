@IsTest
private class QualityTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    /******** matchingRules ********/

    @IsTest
    private static void matchingRules() {
        System.runAs(getUser()) {
            // Setup
            Quality.MatchingRulesRequest request = new Quality.MatchingRulesRequest();
            request.action = 'Promotion';
            request.pipeline = getPipelineId();
            request.platform = 'Other';

            // Exercise
            Test.startTest();
            Quality.MatchingRulesResult result = Quality.matchingRules(request);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Result is not null');
            System.assertEquals(1, result.qualityGates.size(), '1 quality gate should be returned');
            System.assertEquals('Rule1', result.qualityGates[0].Quality_Gate_Rule__r.Name, 'Quality Rule name should match');
            System.assertEquals(
                'Before',
                result.qualityGates[0].Quality_Gate_Rule__r.Execution_sequence__c,
                'Quality Rule execution sequence should match'
            );
        }
    }

    @IsTest
    private static void matchingRulesException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Quality.MatchingRulesResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Quality.matchingRules(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        }
    }

    /******** matchingRules ********/

    /******** steps ********/

    @IsTest
    private static void steps() {
        System.runAs(getUser()) {
            // Setup
            Quality.StepsRequest request = new Quality.StepsRequest();
            request.action = 'Promotion';
            request.pipeline = getPipelineId();
            request.platform = 'Other';

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.steps.size(), 'Should have 1 execution step model');
            System.assertEquals('Before', result.steps[0].sequence, 'Should be pre steps');
            System.assertEquals(1, result.steps[0].steps.size(), 'Should have 1 pre step');
        }
    }

    @IsTest
    private static void stepsException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Quality.StepsResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Quality.steps(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        }
    }

    /******** steps ********/

    private static void createData() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );
        insert extensionConfig;
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        Pipeline pipeline = new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                            .add(new UserStoryMetadata().name('MyClass').type('ApexClass'))
                    )
            );

        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .actions(new List<String>{ 'Promotion', 'PromotionDeployment' })
            .sequence('Before')
            .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
            .active(false)
            .name('Rule1')
            .add(new QualityGateRuleCondition().platform('Other').pipeline(pipeline).extensionConfiguration(extensionConfig.Id))
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getPipelineId() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;
    }
}