@IsTest
private with sharing class DeleteDataCommitDeploymentTaskTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void deleteMultipleDataCommit() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            List<User_Story_Data_Commit__c> dataCommits = getUserStoryDataCommits();

            // Exercise
            Test.startTest();
            delete dataCommits;
            Test.stopTest();

            // Verify
            List<Deployment_Task__c> deploymentTasks = getDeploymentTasks(userStory.Id);
            List<Data_Set__c> dataSets = getDataSets();

            System.assertEquals(0, deploymentTasks.size(), 'Deployment Tasks records should be deleted');
            System.assertEquals(0, dataSets.size(), 'Data Sets records should be deleted');
        }
    }

    @IsTest
    private static void deleteDataCommitForSameDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            List<User_Story_Data_Commit__c> dataCommits = getUserStoryDataCommits();
            // create new data commit for the same data Set, the deployment task shold not be deleted
            User_Story_Data_Commit__c existingDataCommit = dataCommits[0];
            User_Story_Data_Commit__c newDataCommit = new User_Story_Data_Commit__c(
                User_Story__c = existingDataCommit.User_Story__c,
                Data_Set__c = existingDataCommit.Data_Set__c
            );
            insert newDataCommit;

            // Exercise
            Test.startTest();
            delete dataCommits;
            Test.stopTest();

            // Verify
            List<Deployment_Task__c> deploymentTasks = getDeploymentTasks(userStory.Id);
            List<Data_Set__c> dataSets = getDataSets();

            System.assertEquals(1, deploymentTasks.size(), 'Deployment Tasks records should not be deleted because the same Data Set is in another Data Commit');
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
        List<Deployment__c> deployments = new List<Deployment__c>();
        for (Integer i = 0; i < 2; i++) {
            dataSets.add(new Data_Set__c(Name = 'Data Set ' + i, Data_Template__c = dataTemplate.Id));
            deployments.add(createDeployment(orgs[0].Id));
        }
        insert dataSets;
        insert deployments;
        List<User_Story_Data_Commit__c> dataCommits = new List<User_Story_Data_Commit__c>();
        for (Integer i = 0; i < 2; i++) {
            Data_Set__c dataSet = dataSets[i];
            Deployment__c deployment = deployments[i];
            dataCommits.add(createDataCommit(userStory.Id, dataSet.Id, deployment.Id));
        }
        insert dataCommits;
    }

    private static Deployment__c createDeployment(Id orgId) {
        Deployment__c deployment = TestDataFactory.createDeployment(
            'generate data set',
            Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
            orgId
        );
        deployment.Status__c = 'Completed Succesfully';
        return deployment;
    }

    private static User_Story_Data_Commit__c createDataCommit(Id userStoryId, Id dataSetId, Id deploymentId) {
        User_Story_Data_Commit__c dataCommit = new User_Story_Data_Commit__c(
            User_Story__c = userStoryId,
            Data_Set__c = dataSetId,
            Execution_Job__c = deploymentId
        );
        return dataCommit;
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Name FROM User_Story__c LIMIT 1];
    }

    private static List<Data_Set__c> getDataSets() {
        return [SELECT Id, Data_Template__c FROM Data_Set__c];
    }

    private static List<User_Story_Data_Commit__c> getUserStoryDataCommits() {
        return [SELECT Id, User_Story__c, Data_Set__c FROM User_Story_Data_Commit__c];
    }

    private static List<Deployment_Task__c> getDeploymentTasks(Id userStoryId) {
        return [SELECT Id, User_Story__c, dataJSON__c, Perform_Manual_Task__c, Type__c FROM Deployment_Task__c WHERE User_Story__c = :userStoryId];
    }
}