@isTest
private with sharing class DataSetJobExecutionsCtrlTest {
    @TestSetup
    private static void setup() {
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createTestData();
        }
    }

    @IsTest
    private static void getJobExecutionIds() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();

            //  Exercise
            Test.startTest();
            List<Id> jobExecs = DataSetJobExecutionsCtrl.getJobExecutionIds(dataSet.Id);
            Test.stopTest();

            // Verify
            Assert.areEqual(1, jobExecs.size(), 'There should be one Job Execution');
        }
    }

    private static Data_Set__c getDataSet() {
        Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c LIMIT 1];
        return dataSet;
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
        Deployment__c deployment = TestDataFactory.createDeployment(
            'generate data set',
            Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
            orgs[0].Id
        );
        insert deployment;
        Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not started', 1, null, null);
        step.ParentId__c = dataSet.Id;
        insert step;

        new JobExecution().deployment(deployment.Id).persist();
    }
}