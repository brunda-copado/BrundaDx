@IsTest
private with sharing class ScopeCtrlTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getDataFromStep() {
        // Setup
        System.runAs(getUser()) {
            User_Story__c userStory = getUserStory();
            JobStep__c jobStep = (JobStep__c) new JobStep()
                .order(1)
                .type('Manual')
                .name('Manual Task')
                .userStory(userStory.Id)
                .executionSequence('before')
                .persist();

            // Exercise
            Test.startTest();
            ScopeCtrl.ScopeData data = ScopeCtrl.getData(jobStep.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(3, data.stagesById.size(), '3 stage should be returned');
            System.assertEquals(5, data.environmentsById.size(), '5 environments should be returned');
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Credential dev1Cred = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Cred);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1').stageConnection(devStageConnection))
            .add(new Connection(dev2, integration).branch('dev2').stageConnection(devStageConnection))
            .add(new Connection(integration, uat).branch('int').stageConnection(devStageConnection))
            .add(new Connection(uat, prod).branch('uat').stageConnection(testStageConnection))
            .add(devStageConnection)
            .add(testStageConnection)
            .add(productionStageConnection)
            .add(new Project().add(new UserStory().credential(dev1Cred)))
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c testStageConnectionRecord = getStageConnections('Test');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = testStageConnectionRecord.Id;
        testStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update new List<Stage_Connection__c>{ devStageConnectionRecord, testStageConnectionRecord };
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }
}