@IsTest
private with sharing class StagesTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void deleteStageInUse() {
        System.runAs(getUser()) {
            // Setup
            createData();
            Stage__c stage = getStage('Dev');

            Exception error;

            // Exercise
            Test.startTest();
            try {
                delete stage;
            } catch (Exception ex) {
                error = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, error, 'There should be an exception thrown');
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, error.getDmlType(0), 'Exception type does not match.');
            System.assert(error.getMessage().contains(Label.Stages_In_Use_Cannot_Be_Deleted), 'Error message does not match: ' + error.getMessage());
        }
    }

    @IsTest
    private static void deleteStageNotInUse() {
        System.runAs(getUser()) {
            // Setup
            Stage__c stage = (Stage__c) new Stage().name('Test').metaStage('Test').persist();

            Exception error;

            // Exercise
            Test.startTest();
            try {
                delete stage;
            } catch (Exception ex) {
                error = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, error, 'There should not be an exception thrown');
            System.assertEquals(0, [SELECT COUNT() FROM Stage__c], 'Stage record should be deleted');
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, prod).branch('dev1').stageConnection(devStageConnection))
            .add(devStageConnection)
            .add(productionStageConnection)
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update devStageConnectionRecord;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Stage__c getStage(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }
}