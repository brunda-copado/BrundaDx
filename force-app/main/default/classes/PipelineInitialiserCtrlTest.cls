@isTest
private class PipelineInitialiserCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData(true);
        }
    }

    @IsTest
    private static void testWithNoComponentName() {
        System.runAs(getRunAsUser()) {
            //Setup
            Id pipelineId = getPipeline();

            //Exercise
            Test.startTest();
            String componentName = PipelineInitialiserCtrl.getInitializationComponentName(pipelineId);
            Test.stopTest();

            //Verify
            Assert.isTrue(String.isBlank(componentName), 'There is no component for the given platform');
        }
    }

    @IsTest
    private static void testWithValidComponentName() {
        System.runAs(getRunAsUser()) {
            //Setup

            Id pipelineId = getPipeline();
            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'Other'),
                    Key__c = PipelineInitialiserCtrl.PIPELINE_INITIALIZER,
                    Value__c = 'copado:testpage'
                )
            };

            //Exercise
            Test.startTest();
            String componentName = PipelineInitialiserCtrl.getInitializationComponentName(pipelineId);
            Test.stopTest();

            //Verify
            Assert.areEqual(componentName, 'copado:testpage', 'The component name matches');
        }
    }

    @IsTest
    private static void testWithException() {
        System.runAs(getRunAsUser()) {
            //Setup
            Exception expectedException;
            String componentName;

            //Exercise
            Test.startTest();
            try {
                componentName = PipelineInitialiserCtrl.getInitializationComponentName('a00zkc');
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            //Verify
            Assert.isNull(componentName, 'There is an exception');
            Assert.isNotNull(expectedException, 'There is an exception');
            Assert.areEqual('Invalid id: a00zkc', expectedException.getMessage(), 'The exception message matches');
        }
    }

    private static Deployment_Flow__c createData(Boolean createPipelineAction) {
        Credential source = new Credential();

        return (Deployment_Flow__c) new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(new Project().add(new UserStory().credential(source)))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;
    }
}