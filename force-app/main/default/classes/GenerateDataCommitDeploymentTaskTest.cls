@IsTest
private with sharing class GenerateDataCommitDeploymentTaskTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void commitDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            List<Data_Set__c> dataSets = getDataSets();
            Data_Set__c dataSet = dataSets[0];

            // Exercise
            Test.startTest();
            User_Story_Data_Commit__c dataCommit = createDataCommit(userStory.Id, dataSet.Id);
            insert dataCommit;
            Test.stopTest();

            // Verify
            List<Deployment_Task__c> deploymentTasks = getDeploymentTasks(userStory.Id);

            System.assertEquals(1, deploymentTasks.size(), 'Deployment Task record should be created');
            System.assertEquals('Data Template', deploymentTasks[0].Type__c, 'Task type should be Data Template');
            System.assertEquals('After Deployment', deploymentTasks[0].Perform_Manual_Task__c, 'Task should be performed after deployment');
            DataStepData stepData = (DataStepData) JSON.deserialize(deploymentTasks[0].dataJSON__c, DataStepData.class);
            Id sourceDataSet = stepData.source?.id != null && stepData.source?.id instanceof Id ? stepData.source.Id : null;
            System.assertEquals(dataSet.Id, sourceDataSet, 'Task should be linked to the Data Set in the dataJSON field');
        }
    }

    @IsTest
    private static void commitMultipleDataSets() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            List<Data_Set__c> dataSets = getDataSets();

            // Exercise
            Test.startTest();
            List<User_Story_Data_Commit__c> dataCommits = new List<User_Story_Data_Commit__c>();
            for (Integer i = 0; i < dataSets.size(); i++) {
                Data_Set__c dataSet = dataSets[i];
                dataCommits.add(createDataCommit(userStory.Id, dataSet.Id));
            }
            insert dataCommits;
            Test.stopTest();

            // Verify
            List<Deployment_Task__c> deploymentTasks = getDeploymentTasks(userStory.Id);

            System.assertEquals(2, deploymentTasks.size(), 'Deployment Tasks record should be created');
            for (Integer i = 0; i < deploymentTasks.size(); i++) {
                Deployment_Task__c deploymentTask = deploymentTasks[i];
                Data_Set__c dataSet = dataSets[i];
                System.assertEquals('Data Template', deploymentTask.Type__c, 'Task type should be Data Template');
                System.assertEquals('After Deployment', deploymentTask.Perform_Manual_Task__c, 'Task should be performed after deployment');
                DataStepData stepData = (DataStepData) JSON.deserialize(deploymentTask.dataJSON__c, DataStepData.class);
                Id sourceDataSet = stepData.source?.id != null && stepData.source?.id instanceof Id ? stepData.source.Id : null;
                System.assertEquals(dataSet.Id, sourceDataSet, 'Task should be linked to the Data Set in the dataJSON field');
            }
        }
    }

    @IsTest
    private static void commitSameDataSets() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            List<Data_Set__c> dataSets = getDataSets();
            Data_Set__c dataSet = dataSets[0];

            // Exercise
            Test.startTest();
            List<User_Story_Data_Commit__c> dataCommits = new List<User_Story_Data_Commit__c>();
            for (Integer i = 0; i < 2; i++) {
                dataCommits.add(createDataCommit(userStory.Id, dataSet.Id));
            }
            insert dataCommits;
            Test.stopTest();

            // Verify
            List<Deployment_Task__c> deploymentTasks = getDeploymentTasks(userStory.Id);

            System.assertEquals(1, deploymentTasks.size(), 'Deployment Task record should be created');
            System.assertEquals('Data Template', deploymentTasks[0].Type__c, 'Task type should be Data Template');
            System.assertEquals('After Deployment', deploymentTasks[0].Perform_Manual_Task__c, 'Task should be performed after deployment');
            DataStepData stepData = (DataStepData) JSON.deserialize(deploymentTasks[0].dataJSON__c, DataStepData.class);
            Id sourceDataSet = stepData.source?.id != null && stepData.source?.id instanceof Id ? stepData.source.Id : null;
            System.assertEquals(dataSet.Id, sourceDataSet, 'Task should be linked to the Data Set in the dataJSON field');
        }
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
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;
        User_Story__c userStory = TestDataFactory.createUserStory('test', null, null, null, null, orgs[0].Id);
        insert userStory;
        Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('test', orgs.get(0).Id, 'Account', null, null, null, null, null);
        List<Data_Set__c> dataSets = new List<Data_Set__c>();
        for (Integer i = 0; i < 2; i++) {
            dataSets.add(new Data_Set__c(Name = 'Data Set ' + i, Data_Template__c = dataTemplate.Id));
        }
        insert dataSets;
    }

    private static User_Story_Data_Commit__c createDataCommit(Id userStoryId, Id dataSetId) {
        User_Story_Data_Commit__c dataCommit = new User_Story_Data_Commit__c(User_Story__c = userStoryId, Data_Set__c = dataSetId);
        return dataCommit;
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Name FROM User_Story__c LIMIT 1];
    }

    private static List<Data_Set__c> getDataSets() {
        return [SELECT Id, Data_Template__c FROM Data_Set__c];
    }

    private static List<Deployment_Task__c> getDeploymentTasks(Id userStoryId) {
        return [SELECT Id, User_Story__c, dataJSON__c, Perform_Manual_Task__c, Type__c FROM Deployment_Task__c WHERE User_Story__c = :userStoryId];
    }
}