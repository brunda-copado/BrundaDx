@IsTest
private class ResultViewerPublishMessageCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void getToolForTest() {
        System.runAs(getRunAsUser()) {
            // Setup

            ExtensionConfiguration extensionConfig = new ExtensionConfiguration().active(true).tool('Manual Tests').application('Test');
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });

            new QualityGateRule().action('Commit').sequence('After').tool('None').active(false).name('RuleCommit');

            JobStep consolidatedStep = new JobStep().name('Step 1').type('Manual').order(1).add(new Result()).configJson('');

            new Test_t().extensionConfiguration(extensionConfig).jobExecution(new JobExecution().status('In Progress').add(consolidatedStep));

            new JobExecution().consolidatedStep(consolidatedStep).add(new JobStep().name('Step 2').add(new Result())).persist();

            List<Result__c> results = [SELECT Id FROM Result__c WHERE JobStep__r.Name = 'Step 1'];

            // Exercise
            String tool = ResultViewerPublishMessageCtrl.getTool(results[0].Id);

            // Verify
            Assert.areEqual('Manual Tests', tool, 'Tool should be Manual Tests.');
        }
    }

    @IsTest
    private static void getToolForQualityGate() {
        System.runAs(getRunAsUser()) {
            // Setup

            ExtensionConfiguration extensionConfig = new ExtensionConfiguration().active(true).tool('Manual Tests').application('Test');
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
            QualityGateRuleCondition qrc = new QualityGateRuleCondition().extensionConfiguration(extensionConfig);

            new QualityGateRule().action('Commit').sequence('After').tool('None').active(false).name('RuleCommit').add(qrc);

            JobStep consolidatedStep = new JobStep()
                .name('Step 1')
                .type('Manual')
                .order(1)
                .add(new Result())
                .configJson('')
                .qualityRuleCondition(qrc);
            new JobExecution().status('In Progress').add(consolidatedStep).persist();

            Quality_Gate_Rule__c rule = [SELECT Status__c FROM Quality_Gate_Rule__c LIMIT 1];
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            JobStep__c step = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];

            new JobExecution().consolidatedStep(step.Id).add(new JobStep().name('Step 2').add(new Result())).persist();

            List<Result__c> results = [SELECT Id FROM Result__c WHERE JobStep__r.Name = 'Step 2'];

            // Exercise
            String tool = ResultViewerPublishMessageCtrl.getTool(results[0].Id);

            // Verify
            Assert.areEqual('Manual Tests', tool, 'Tool should be Manual Tests.');
        }
    }

    @IsTest
    private static void getToolForQualityCheck() {
        System.runAs(getRunAsUser()) {
            // Setup

            ExtensionConfiguration extensionConfig = new ExtensionConfiguration().active(true).tool('Manual Tests').application('Test');
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
            QualityGateRuleCondition qrc = new QualityGateRuleCondition().extensionConfiguration(extensionConfig);

            new QualityGateRule().action('Commit').sequence('After').tool('None').active(false).name('RuleCommit').add(qrc);

            JobStep consolidatedStep = new JobStep()
                .name('Step 1')
                .type('Manual')
                .order(1)
                .add(new Result())
                .configJson('');
                
            new JobExecution().status('In Progress')
           .add(consolidatedStep).persist();

            Quality_Gate_Rule__c rule = [SELECT Status__c FROM Quality_Gate_Rule__c LIMIT 1];
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            JobStep__c step = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];

            new JobExecution().dataJson('{ "qualityCheck" : "' + qrc.Id + '"}').consolidatedStep(step.Id).add(new JobStep().name('Step 2').add(new Result())).persist();

            List<Result__c> results = [SELECT Id FROM Result__c WHERE JobStep__r.Name = 'Step 2'];

            // Exercise
            String tool = ResultViewerPublishMessageCtrl.getTool(results[0].Id);

            // Verify
            Assert.areEqual('Manual Tests', tool, 'Tool should be Manual Tests.');
        }
    }


    // HELPER

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}