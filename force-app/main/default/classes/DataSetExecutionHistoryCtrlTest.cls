@IsTest
private with sharing class DataSetExecutionHistoryCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void getSteps() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();

            //  Exercise
            Test.startTest();
            List<Step__c> steps = DataSetExecutionHistoryCtrl.getDeploymentSteps(dataSet.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, steps.size(), 'There should be one step');
        }
    }

    private static Data_Set__c getDataSet() {
        Data_Set__c dataSet = [SELECT Id, Data_Template__c FROM Data_Set__c LIMIT 1];
        return dataSet;
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
        Deployment__c deployment = TestDataFactory.createDeployment(
            'generate data set',
            Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
            orgs[0].Id
        );
        insert deployment;
        Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not started', 1, null, null);
        step.ParentId__c = dataSet.Id;
        insert step;
    }
}