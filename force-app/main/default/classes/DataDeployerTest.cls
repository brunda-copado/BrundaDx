@IsTest
private class DataDeployerTest {
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
            Org__c org = getOrg();

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataTemplate.Id)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .sourceCredentialId(org.Id)
                .destinationType(DataDeployRequest.Destination.ENVIRONMENT)
                .destinationCredentialId(org.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentId);
            verifyStep(deploymentId, dataTemplate.Id, null, 'ENVIRONMENT', 'ENVIRONMENT');
        }
    }

    @IsTest
    private static void deployDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            Org__c org = getOrg();

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.DATASET)
                .sourceDataSetId(dataSet.Id)
                .destinationType(DataDeployRequest.Destination.ENVIRONMENT)
                .destinationCredentialId(org.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentId);
            verifyStep(deploymentId, null, dataSet.Id, 'DATASET', 'ENVIRONMENT');
        }
    }

    @IsTest
    private static void generateDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            Org__c org = getOrg();

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .destinationType(DataDeployRequest.Destination.DATASET)
                .destinationDataSetId(dataSet.Id)
                .deployNow(false);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentId);
            verifyStep(deploymentId, null, dataSet.Id, 'ENVIRONMENT', 'DATASET');
        }
    }

    @IsTest
    private static void generateDataSetNow() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            Org__c org = getOrg();
            mockDeploy();

            // Exercise
            Test.startTest();
            DataDeployRequest request = new DataDeployRequest()
                .dataTemplateId(dataSet.Data_Template__c)
                .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                .sourceCredentialId(org.Id)
                .destinationType(DataDeployRequest.Destination.DATASET)
                .destinationDataSetId(dataSet.Id)
                .deployNow(true);
            DataDeployer dataDeployer = new DataDeployer(request);
            Id deploymentId = dataDeployer.execute();
            Test.stopTest();

            // Verify
            verifyDeployment(deploymentId);
            verifyDeploymentScheduled(deploymentId);
            verifyStep(deploymentId, dataSet.Data_Template__c, dataSet.Id, 'ENVIRONMENT', 'DATASET');
            verifyDataSetDetails(deploymentId, dataSet);
        }
    }

    @IsTest
    private static void invalidRequests() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            Org__c org = getOrg();

            // Exercise + Verify
            Test.startTest();
            List<DataDeployRequest> invalidRequests = new List<DataDeployRequest>();

            invalidRequests.add(new DataDeployRequest());
            invalidRequests.add(new DataDeployRequest().sourceType(DataDeployRequest.Source.ENVIRONMENT));
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.ENVIRONMENT).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.DATASET).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest().sourceType(DataDeployRequest.Source.BRANCH).destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest()
                    .dataTemplateId(dataSet.Data_Template__c)
                    .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                    .destinationType(DataDeployRequest.Destination.DATASET)
            );
            invalidRequests.add(
                new DataDeployRequest()
                    .dataTemplateId(dataSet.Data_Template__c)
                    .sourceType(DataDeployRequest.Source.ENVIRONMENT)
                    .destinationType(DataDeployRequest.Destination.BRANCH)
            );
            for (DataDeployRequest invalidRequest : invalidRequests) {
                try {
                    DataDeployer dataDeployer = new DataDeployer(invalidRequest);
                } catch (DataDeployer.DataDeployerException e) {
                    System.assert(true, 'No validation exception was thrown');
                }
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void getTypeFromString() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Exercise + Verify
            Test.startTest();
            System.assertEquals(
                DataDeployRequest.Source.ENVIRONMENT,
                DataDeployRequest.sourceTypeFromString('ENVIRONMENT'),
                'Enum value should be ENVIRONMENT'
            );
            System.assertEquals(DataDeployRequest.Source.DATASET, DataDeployRequest.sourceTypeFromString('DATASET'), 'Enum value should be DATASET');
            System.assertEquals(DataDeployRequest.Source.BRANCH, DataDeployRequest.sourceTypeFromString('BRANCH'), 'Enum value should be BRANCH');
            System.assertEquals(
                DataDeployRequest.Destination.ENVIRONMENT,
                DataDeployRequest.destinationTypeFromString('ENVIRONMENT'),
                'Enum value should be ENVIRONMENT'
            );
            System.assertEquals(
                DataDeployRequest.Destination.DATASET,
                DataDeployRequest.destinationTypeFromString('DATASET'),
                'Enum value should be DATASET'
            );
            System.assertEquals(
                DataDeployRequest.Destination.BRANCH,
                DataDeployRequest.destinationTypeFromString('BRANCH'),
                'Enum value should be BRANCH'
            );
            Test.stopTest();
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

    private static void verifyDeployment(Id deploymentId) {
        List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Id = :deploymentId];
        System.assertNotEquals(0, deployments.size(), 'Deployment record should be created.');
    }

    private static void verifyDeploymentScheduled(Id deploymentId) {
        List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id = :deploymentId];
        System.assertEquals('Scheduled', deployments[0].Status__c, 'Deployment should have Scheduled status.');
    }

    private static void verifyStep(Id deploymentId, Id dataTemplateId, Id dataSetId, String source, String destination) {
        List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :deploymentId];
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

    private static void verifyDataSetDetails(Id deploymentId, Data_Set__c dataSet) {
        List<Deployment__c> deployments = [SELECT Id, Status__c FROM Deployment__c WHERE Id = :deploymentId];
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

    private static void mockDeploy() {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', '{}', null);
        Test.setMock(HttpCalloutMock.class, mockResponse);
    }
}