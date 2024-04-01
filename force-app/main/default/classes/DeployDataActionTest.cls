@IsTest
private class DeployDataActionTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void deployDataTemplate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createDeployDataTemplateRequest(dataTemplate.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentIds);
            verifyStep(deploymentIds, dataTemplate.Id, null, 'ENVIRONMENT', 'ENVIRONMENT');
        }
    }

    @IsTest
    private static void deployDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createDeployDataSetRequest(dataSet.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentIds);
            verifyStep(deploymentIds, null, dataSet.Id, 'DATASET', 'ENVIRONMENT');
        }
    }

    @IsTest
    private static void generateDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createGenerateDataSetRequest(dataSet.Data_Template__c, dataSet.Id);
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentIds);
            verifyStep(deploymentIds, null, dataSet.Id, 'ENVIRONMENT', 'DATASET');
        }
    }

    @IsTest
    private static void generateDataSetNow() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            mockDeploy();

            // Exercise
            Test.startTest();
            DeployDataAction.Request request = createGenerateDataSetRequest(dataSet.Data_Template__c, dataSet.Id);
            request.deployNow = true;
            List<Id> deploymentIds = DeployDataAction.execute(new List<DeployDataAction.Request>{ request });
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentIds);
            verifyDeploymentScheduled(deploymentIds);
            verifyStep(deploymentIds, dataSet.Data_Template__c, dataSet.Id, 'ENVIRONMENT', 'DATASET');
            verifyDataSetDetails(deploymentIds, dataSet);
        }
    }

    private static Data_Set__c getDataSet() {
        Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c LIMIT 1];
        return dataSet;
    }

    private static Data_Template__c getDataTemplate() {
        Data_Template__c dataTemplate = [SELECT Id FROM Data_Template__c LIMIT 1];
        return dataTemplate;
    }

    private static Org__c getOrg() {
        Org__c org = [SELECT Id FROM Org__c];
        return org;
    }

    private static void verifyDeployment(List<Id> deploymentIds) {
        System.assert(!deploymentIds.isEmpty(), 'Deployment record should be created.');
    }

    private static void verifyDeploymentScheduled(List<Id> deploymentIds) {
        List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id IN :deploymentIds];
        System.assertEquals('Scheduled', deployments[0].Status__c, 'Deployment should have Scheduled status.');
    }

    private static void verifyStep(List<Id> deploymentIds, Id dataTemplateId, Id dataSetId, String source, String destination) {
        List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c IN :deploymentIds];
        System.assertEquals(1, steps.size(), 'Deployment should have one step.');
        Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
        if (dataTemplateId != null) {
            System.assertEquals(dataTemplateId, stepData.get('dataTemplateId'), 'Data Template Id from Step dataJson should match');
        }
        System.assertEquals(source, ((Map<String, Object>) stepData.get('source')).get('type'), 'Source type in Step dataJson should be ' + source);
        if (source == 'DATASET') {
            System.assertEquals(
                dataSetId,
                ((Map<String, Object>) stepData.get('source')).get('id'),
                'Source Id from Step dataJson should match the record Id'
            );
        }
        System.assertEquals(
            destination,
            ((Map<String, Object>) stepData.get('destination')).get('type'),
            'Destination type in Step dataJson should be ' + destination
        );
        if (destination == 'DATASET') {
            System.assertEquals(
                dataSetId,
                ((Map<String, Object>) stepData.get('destination')).get('id'),
                'Destination Id from Step dataJson should match the record Id'
            );
        }
    }

    private static void verifyDataSetDetails(List<Id> deploymentIds, Data_Set__c dataSet) {
        List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id IN :deploymentIds];
        List<Data_Set__c> dataSets = [SELECT Id, Last_Generated_Date__c, Execution_Job__c, Source_Org__c FROM Data_Set__c WHERE Id = :dataSet.Id];
        System.assertNotEquals(null, dataSets[0].Last_Generated_Date__c, 'Data Set last generated date should be updated.');
        System.assertEquals(deployments[0].Id, dataSets[0].Execution_Job__c, 'Data Set execution job should be updated.');
        System.assertNotEquals(null, dataSets[0].Source_Org__c, 'Data Set source environment should be updated.');
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }

    private static void createTestData() {
        Data_Template__c dataTemplate = new Data_Template__c();
        insert dataTemplate;
        Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id);
        insert dataSet;
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;
    }

    private static DeployDataAction.Request createDeployDataTemplateRequest(Id dataTemplateId) {
        Id orgId = getOrg().Id;
        return createRequest(dataTemplateId, 'ENVIRONMENT', 'ENVIRONMENT', orgId, orgId, null, null, null, null, false);
    }

    private static DeployDataAction.Request createDeployDataSetRequest(Id dataSetId) {
        Id orgId = getOrg().Id;
        return createRequest(null, 'DATASET', 'ENVIRONMENT', orgId, orgId, dataSetId, null, null, null, false);
    }

    private static DeployDataAction.Request createGenerateDataSetRequest(Id dataTemplateId, Id dataSetId) {
        return createRequest(dataTemplateId, 'ENVIRONMENT', 'DATASET', null, null, null, dataSetId, null, null, false);
    }

    private static DeployDataAction.Request createRequest(
        String dataTemplateId,
        String sourceType,
        String destinationType,
        String sourceCredentialId,
        String destinationCredentialId,
        String sourceDataSetId,
        String destinationDataSetId,
        String sourceBranchName,
        String destinationBranchName,
        Boolean deployNow
    ) {
        DeployDataAction.Request request = new DeployDataAction.Request();
        request.dataTemplateId = dataTemplateId;
        request.sourceType = sourceType;
        request.destinationType = destinationType;
        request.sourceCredentialId = sourceCredentialId;
        request.destinationCredentialId = destinationCredentialId;
        request.sourceDataSetId = sourceDataSetId;
        request.destinationDataSetId = destinationDataSetId;
        request.sourceBranchName = sourceBranchName;
        request.destinationBranchName = destinationBranchName;
        request.deployNow = deployNow;
        return request;
    }

    private static void mockDeploy() {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', '{}', null);
        Test.setMock(HttpCalloutMock.class, mockResponse);
    }
}