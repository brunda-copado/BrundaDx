@isTest
public with sharing class EnvironmentVarPipelineRelatedCtrlTest {
    //Setup
    @TestSetup
    static void setupData(){
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    private static void data(){
        Git_Repository__c gitRepo = TestDataFactory.createGitRepository();
        insert gitRepo;
        
        List<Environment__c> environments = TestDataFactory.createEnvironments(3);

        List<Org__c> orgs = new List<Org__c>();
        for (Integer i=0;i<3;i++) {
            Org__c o = TestDataFactory.createOrgCredentials('Test', environments[i].Id, 'Production/Developer');
            orgs.add(o);
        }
        insert orgs;

        Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('Test Pipeline', true, gitRepo.Id, false);
        insert pipeline;

        List<Deployment_Flow_Step__c> deploymentStep = new List<Deployment_Flow_Step__c>();
        for (Integer i=0;i<2;i++) {
            Deployment_Flow_Step__c dfs = TestDataFactory.createDeploymentFlowStep(environments[i].Id, environments[i+1].Id, pipeline.Id, '');
            deploymentStep.add(dfs);
        }
        insert deploymentStep;

        List<Environmental_Variable__c> environmentalVariable = new List<Environmental_Variable__c>();
        for(Integer j=0;j<2;j++){
            Environmental_Variable__c ev = TestDataFactory.createEnvironmentVariable('Test', 'admin@test.com'+j, '', environments[j].Id);
            environmentalVariable.add(ev);
        }
        insert environmentalVariable;
    }
          

    @isTest
    private static void fetchDataTest(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Setup
            data();
            Deployment_Flow__c pipeline = [SELECT Id, Name FROM Deployment_Flow__c WHERE Name ='Test Pipeline' LIMIT 1];
            Environmental_Variable__c environmentalVariable = [SELECT Id, Name, Scope__c, Value__c, Environment__c FROM Environmental_Variable__c WHERE Name ='Test' LIMIT 1];

            Test.startTest();
            //Exercise
            List<Environmental_Variable__c> environmentalVariableList = EnvironmentVarPipelineRelatedListCtrl.fetchData(pipeline.Id, 'Deployment_Flow__c');
            List<EnvironmentVarPipelineRelatedListCtrl.EnvironmentVarWrapper> environmentWrapper = EnvironmentVarPipelineRelatedListCtrl.fetchRows(environmentalVariable, pipeline.Id, 'Deployment_Flow__c');

            List<Environmental_Variable__c> environmentalVariableList1 = EnvironmentVarPipelineRelatedListCtrl.fetchData(environmentalVariable.Environment__c, 'Environment__c');
            List<EnvironmentVarPipelineRelatedListCtrl.EnvironmentVarWrapper> environmentWrapper1 = EnvironmentVarPipelineRelatedListCtrl.fetchRows(environmentalVariable, environmentalVariable.Environment__c, 'Environment__c');
            Test.stopTest();

            //Verify
            System.assertEquals(1, environmentalVariableList.size());
            System.assertEquals(3, environmentWrapper.size());

            System.assertEquals(1, environmentalVariableList1.size());
            System.assertEquals(1, environmentWrapper1.size());
            
        }
    }

    @isTest
    private static void onSaveTest(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Setup
            data();
            List<Environment__c> environments = [SELECT Id FROM Environment__c];
            String environmentVar = '{"variableName":"testing1","scope":"","environmentValue":[{"environment":"Copado DEV-04","environmentId":"'+environments[0].Id+'","environmentVariableId":"","value":"testting"},{"environment":"AV-Staging","environmentId":"'+environments[1].Id+'","environmentVariableId":"","value":"testting"}]}';

            Test.startTest();
            //Exercise
            EnvironmentVarPipelineRelatedListCtrl.onSave(environmentVar, false);
            Test.stopTest();
        }
    }

    @isTest
    private static void onDeleteTest(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Setup
            data();
            Environmental_Variable__c environmentalVariable = [SELECT Id, Name, Scope__c, Value__c, Environment__c FROM Environmental_Variable__c WHERE Name ='Test' LIMIT 1];
            Test.startTest();
            //Exercise
            EnvironmentVarPipelineRelatedListCtrl.onDelete(environmentalVariable, 'Deployment_Flow__c');
            EnvironmentVarPipelineRelatedListCtrl.onDelete(environmentalVariable, 'Environment__c');
            Test.stopTest();
        }
    }


}