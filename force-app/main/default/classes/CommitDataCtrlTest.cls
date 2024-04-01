@IsTest
private with sharing class CommitDataCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }
    
    @IsTest
    private static void commitDataTemplate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            Data_Template__c dataTemplate = getDataTemplate();
            String commitMessage = 'test';
            List<DataFilter> filters;
            String filterLogic;
            mockDeployment();
            
            // Exercise
            Test.startTest();
            Id dataCommitId = CommitDataCtrl.commitData(userStory.Id, 'ENVIRONMENT', dataTemplate.Id, null, commitMessage, filters, filterLogic);
            Test.stopTest();
            
            // Verify
            List<User_Story_Data_Commit__c> dataCommits = [
                SELECT Id, Commit_Message__c, Data_Set__c, Execution_Job__c
                FROM User_Story_Data_Commit__c
                WHERE Id = :dataCommitId
            ];
            System.assertEquals(false, dataCommits.isEmpty(), 'User Story Data Commit record should be created');
            System.assertEquals(commitMessage, dataCommits[0].Commit_Message__c, 'Commit message should be the same');
            System.assertNotEquals(null, dataCommits[0].Data_Set__c, 'Data Set should be linked to the commit');
            List<Data_Set__c> dataSets = [SELECT Id, Name FROM Data_Set__c];
            System.assertEquals(2, dataSets.size(), 'There should be 2 Data Sets (existing and new one)');
            Data_Set__c commitDataSet = [SELECT Id, Name FROM Data_Set__c WHERE Id = :dataCommits[0].Data_Set__c LIMIT 1];
            System.assertEquals(userStory.Name + '/' + dataTemplate.Name, commitDataSet.Name, 'Data Set name should match');
            System.assertNotEquals(null, dataCommits[0].Execution_Job__c, 'Deployment to generate Data Set files should be created');
        }
    }
    
    @IsTest
    private static void commitDataSet() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            Data_Set__c dataSet = getDataSet();
            String commitMessage = 'test';
            List<DataFilter> filters;
            String filterLogic;
            mockDeployment();
            
            // Exercise
            Test.startTest();
            Id dataCommitId = CommitDataCtrl.commitData(userStory.Id, 'DATASET', null, dataSet.Id, commitMessage, filters, filterLogic);
            Test.stopTest();
            
            // Verify
            List<User_Story_Data_Commit__c> dataCommits = [
                SELECT Id, Commit_Message__c, Data_Set__c, Execution_Job__c
                FROM User_Story_Data_Commit__c
                WHERE Id = :dataCommitId
            ];
            System.assertEquals(false, dataCommits.isEmpty(), 'User Story Data Commit record should be created');
            System.assertEquals(commitMessage, dataCommits[0].Commit_Message__c, 'Commit message should be the same');
            System.assertEquals(dataSet.Id, dataCommits[0].Data_Set__c, 'Data Set should be linked to the commit');
            List<Data_Set__c> dataSets = [SELECT Id, Name FROM Data_Set__c];
            System.assertEquals(1, dataSets.size(), 'There should be only one Data Sets (existing)');
            System.assertEquals(null, dataCommits[0].Execution_Job__c, 'Deployment to generate Data Set files should not be created');
        }
    }
    
    @IsTest
    private static void commitDataTemplateExistingDataCommit() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            Data_Set__c dataSet = getDataSet();
            User_Story_Data_Commit__c dataCommit = new User_Story_Data_Commit__c(Data_Set__c = dataSet.Id, User_Story__c = userStory.Id);
            insert dataCommit;
            String commitMessage = 'test';
            List<DataFilter> filters;
            String filterLogic;
            mockDeployment();
            
            // Exercise
            Test.startTest();
            Id dataCommitId = CommitDataCtrl.commitData(
                userStory.Id,
                'ENVIRONMENT',
                dataSet.Data_Template__c,
                null,
                commitMessage,
                filters,
                filterLogic
            );
            Test.stopTest();
            
            // Verify
            List<User_Story_Data_Commit__c> dataCommits = [
                SELECT Id, Commit_Message__c, Data_Set__c, Execution_Job__c
                FROM User_Story_Data_Commit__c
                WHERE Id = :dataCommitId
            ];
            System.assertEquals(false, dataCommits.isEmpty(), 'User Story Data Commit record should be created');
            System.assertEquals(commitMessage, dataCommits[0].Commit_Message__c, 'Commit message should be the same');
            System.assertNotEquals(null, dataCommits[0].Data_Set__c, 'Data Set should be linked to the commit');
            List<Data_Set__c> dataSets = [SELECT Id, Name FROM Data_Set__c ORDER BY CreatedDate DESC];
            System.assertEquals(1, dataSets.size(), 'There should be only one Data Set');
            System.assertNotEquals(null, dataCommits[0].Execution_Job__c, 'Deployment to generate Data Set files should be linked to the commit');
        }
    }
    
    @IsTest
    private static void commitDataTemplateWithFilters() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            Data_Template__c dataTemplate = getDataTemplate();
            String commitMessage = 'test';
            List<DataFilter> filters = getFilters();
            String filterLogic = getFilterLogic();
            mockDeployment();
            
            // Exercise
            Test.startTest();
            Id dataCommitId = CommitDataCtrl.commitData(userStory.Id, 'ENVIRONMENT', dataTemplate.Id, null, commitMessage, filters, filterLogic);
            Test.stopTest();
            
            // Verify
            List<User_Story_Data_Commit__c> dataCommits = [
                SELECT Id, Commit_Message__c, Data_Set__c, Execution_Job__c
                FROM User_Story_Data_Commit__c
                WHERE Id = :dataCommitId
            ];
            System.assertEquals(false, dataCommits.isEmpty(), 'User Story Data Commit record should be created');
            System.assertEquals(commitMessage, dataCommits[0].Commit_Message__c, 'Commit message should be the same');
            System.assertNotEquals(null, dataCommits[0].Data_Set__c, 'Data Set should be linked to the commit');
            List<Data_Set__c> dataSets = [SELECT Id, Name FROM Data_Set__c];
            System.assertEquals(2, dataSets.size(), 'There should be 2 Data Sets (existing and new one)');
            Data_Set__c commitDataSet = [SELECT Id, Name FROM Data_Set__c WHERE Id = :dataCommits[0].Data_Set__c LIMIT 1];
            System.assertEquals(userStory.Name + '/' + dataTemplate.Name, commitDataSet.Name, 'Data Set name should match');
            System.assertNotEquals(null, dataCommits[0].Execution_Job__c, 'Deployment to generate Data Set files should be created');
            List<Step__c> steps = [SELECT Id, dataJson__c FROM Step__c WHERE Deployment__c = :dataCommits[0].Execution_Job__c];
            System.assertEquals(1, steps.size(), 'Deployment should have one step.');
            Map<String, Object> stepData = (Map<String, Object>) JSON.deserializeUntyped(steps[0].dataJson__c);
            System.assertEquals(false, ((List<Object>) stepData.get('queryFilterList')).isEmpty(), 'Step Data should have filters configured');
            System.assertEquals(filterLogic, String.valueOf(stepData.get('filterLogic')), 'Step Data should have filters configured');
        }
    }
    
    @IsTest
    private static void invalidRequests() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStory = getUserStory();
            Data_Template__c dataTemplate = getDataTemplate();
            Data_Set__c dataSet = getDataSet();
            
            // Exercise + Verify
            Test.startTest();
            List<DataCommitRequest> invalidRequests = new List<DataCommitRequest>();
            
            invalidRequests.add(new DataCommitRequest());
            invalidRequests.add(new DataCommitRequest().userStoryId(userStory.Id));
            invalidRequests.add(new DataCommitRequest().userStoryId(userStory.Id).sourceType(DataCommitRequest.Source.ENVIRONMENT));
            invalidRequests.add(
                new DataCommitRequest().userStoryId(userStory.Id).sourceType(DataCommitRequest.Source.ENVIRONMENT).dataTemplateId(dataTemplate.Id)
            );
            invalidRequests.add(new DataCommitRequest().userStoryId(userStory.Id).sourceType(DataCommitRequest.Source.DATASET));
            invalidRequests.add(new DataCommitRequest().userStoryId(userStory.Id).sourceType(DataCommitRequest.Source.DATASET).dataSetId(dataSet.Id));
            for (DataCommitRequest invalidRequest : invalidRequests) {
                try {
                    new DataCommitter(invalidRequest);
                } catch (ApplicationException e) {
                    System.assert(true, 'No validation exception was thrown');
                }
            }
            Test.stopTest();
        }
    }
    
    @IsTest
    private static void getDataTemplateFilters() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            
            // Exercise
            Test.startTest();
            DataFiltersConfiguration filterConfiguration = CommitDataCtrl.getDataTemplateFiltersConfiguration(dataTemplate.Id);
            Test.stopTest();
            
            // Verify
            List<DataFilter> filters = filterConfiguration.filters;
            String filterLogic = filterConfiguration.filterLogic;
            System.assert(!filters.isEmpty(), 'Data Template filters should be retrieved');
            System.assert(String.isNotBlank(filterLogic), 'Data Template filter Logic should be retrieved');
        }
    }
    
    @isTest
    private static void validateOrgCredential() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            User_Story__c userStory = getUserStory();
            
            // Exercise
            Test.startTest();
            Boolean validCredential = CommitDataCtrl.validateOrgCredential(userStory.Org_Credential__c);
            Test.stopTest();
            
            //Verify
            System.assertEquals(true, validCredential, 'Org Credential must be a valid one');
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
            org.Disable_Validation__c = true;
        }
        update orgs;
        User_Story__c userStory = TestDataFactory.createUserStory('test', null, null, null, null, orgs[0].Id);
        insert userStory;
        Data_Template__c dataTemplate = TestDataFactory.createDataTemplate(
            'test',
            orgs.get(0).Id,
            'Account',
            null,
            null,
            getFilters(),
            getFilterLogic(),
            null
        );
        Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id);
        insert dataSet;
    }
    
    private static User_Story__c getUserStory() {
        return [SELECT Id, Name, Org_Credential__c FROM User_Story__c LIMIT 1];
    }
    
    private static Data_Set__c getDataSet() {
        return [SELECT Id, Data_Template__c FROM Data_Set__c LIMIT 1];
    }
    
    private static Data_Template__c getDataTemplate() {
        return [SELECT Id, Name FROM Data_Template__c LIMIT 1];
    }
    
    private static List<DataFilter> getFilters() {
        List<DataFilter> filters = new List<DataFilter>();
        filters.add(createDataFilter('field1', 'STRING', 'e', 'value1'));
        filters.add(createDataFilter('field2', 'INTEGER', 'e', '2'));
        filters.add(createDataFilter('field3', 'DATE', 'e', '2020-01-01'));
        filters.add(createDataFilter('field4', 'STRING', 'k', 'value'));
        filters.add(createDataFilter('field5', 'INTEGER', 'n', null));
        filters.add(createDataFilter('field6', 'DATETIME', 'n', null));
        filters.add(createDataFilter('field7', 'DATETIME', 'n', 'LAST_N_DAYS:5'));
        filters.add(createDataFilter('Custom Filter', null, null, 'Name != NULL'));
        return filters;
    }
    
    private static String getFilterLogic() {
        return '1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7 AND 8';
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static DataFilter createDataFilter(String fieldName, String fieldType, String operatorCode, String value) {
        DataFilter filter = new DataFilter();
        filter.fieldName = fieldName;
        filter.fieldType = fieldType;
        filter.operatorCode = operatorCode;
        filter.value = value;
        return filter;
    }
    
    private static void mockDeployment() {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', '{}', null);
        Test.setMock(HttpCalloutMock.class, mockResponse);
    }
}