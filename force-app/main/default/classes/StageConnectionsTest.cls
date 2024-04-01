@IsTest
private class StageConnectionsTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .standard()
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void insertDuplicateStage() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new StageConnection().pipelineId(getPipeline()).stageId(getStageByName('Dev')).nextStageConnectionId(getStageConnections('Test').Id).persist();
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assert(validationError.getMessage().contains(Label.Duplicate_Stage_Connection_Error), 'Error message does not match: ' + validationError.getMessage());
        }
    }

    @IsTest
    private static void updateDuplicateStage() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                Stage_Connection__c stageConnection = (Stage_Connection__c) new StageConnection().pipelineId(getPipeline()).stageId(getStageByName('Dev')).persist();
                stageConnection.Next_Stage_Connection__c = getStageConnections('Test').Id;
                update new List<Stage_Connection__c>{ stageConnection };
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assert(validationError.getMessage().contains(Label.Duplicate_Stage_Connection_Error), 'Error message does not match: ' + validationError.getMessage());
        }
    }

    @IsTest
    private static void insertDuplicateNextStage() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                new StageConnection().pipelineId(getPipeline()).stageId(getStageByName('Dev')).nextStageConnectionId(getStageConnections('Production').Id).persist();
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assert(validationError.getMessage().contains(Label.Duplicate_Next_Stage_Connection_Error), 'Error message does not match: ' + validationError.getMessage());
        }
    }

    @IsTest
    private static void updateDuplicateNextStage() {
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Exception validationError;
            try {
                Stage_Connection__c stageConnection = (Stage_Connection__c) new StageConnection().pipelineId(getPipeline()).stageId(getStageByName('Dev')).persist();
                stageConnection.Next_Stage_Connection__c = getStageConnections('Production').Id;
                update new List<Stage_Connection__c>{ stageConnection };
            } catch (Exception e) {
                validationError = e;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, validationError, 'An exception should be thrown.');
            System.assertEquals(
                StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
                validationError.getDmlType(0),
                'Validation exception should be thrown.'
            );
            System.assert(validationError.getMessage().contains(Label.Duplicate_Next_Stage_Connection_Error), 'Error message does not match: ' + validationError.getMessage());
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        Connection dev1Connection = new Connection(dev1, integration).branch('dev1').stageConnection(devStageConnection);
        Connection dev2Connection = new Connection(dev2, integration).branch('dev2').stageConnection(devStageConnection);
        Connection integrationConnection = new Connection(integration, uat).branch('int').stageConnection(devStageConnection);
        Connection uatConnection = new Connection(uat, prod).branch('uat').stageConnection(testStageConnection);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(dev1Connection)
            .add(dev2Connection)
            .add(integrationConnection)
            .add(uatConnection)
            .add(devStageConnection)
            .add(testStageConnection)
            .add(productionStageConnection)
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c testStageConnectionRecord = getStageConnections('Test');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = testStageConnectionRecord.Id;
        testStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update new List<Stage_Connection__c>{ devStageConnectionRecord, testStageConnectionRecord };
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id, Stage__c, Next_Stage_Connection__c FROM Stage_Connection__c WHERE Stage__c = :getStageByName(stageName) ORDER BY CreatedDate LIMIT 1];
    }

    private static Id getStageByName(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1].Id;
    }

    private static Id getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c WHERE Active__c = TRUE LIMIT 1].Id;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}