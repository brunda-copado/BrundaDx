@isTest
private class TestDeploymentTaskExtension {
    @testSetup
    static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static void setupDataDML() {
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        List<Environment__c> environments = new List<Environment__c>();
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('Dev1', '000000000000000001');
        environments.add(env1);
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Dev2', '000000000000000002');
        environments.add(env2);
        Environment__c env3 = CMTestMethodUtilities.createEnvironment('Int', '000000000000000003');
        environments.add(env3);
        Environment__c env4 = CMTestMethodUtilities.createEnvironment('UAT', '000000000000000004');
        environments.add(env4);
        Environment__c env5 = CMTestMethodUtilities.createEnvironment('Prod', '000000000000000005');
        environments.add(env5);
        insert environments;
        System.assertNotEquals(env1.Id, null);
        System.assertNotEquals(env2.Id, null);
        System.assertNotEquals(env3.Id, null);
        System.assertNotEquals(env4.Id, null);
        System.assertNotEquals(env5.Id, null);

        Org__c testOrg = testMethodUtilities.createOrg('OrgName2', 'Sandbox', '000000000000000002', 'SFDC_TOKEN', 'USERNAME', System.now());
        testOrg.Test_Frequency__c = 'Daily';
        testOrg.Environment__c = env1.Id;
        insert testOrg;
        System.assertNotEquals(testOrg.Id, null);
        List<Deployment_Flow_Step__c> flowSteps = new List<Deployment_Flow_Step__c>();
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env3.Id, flow.Id);
        flowSteps.add(dfs);
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env2.Id, env3.Id, flow.Id);
        flowSteps.add(dfs2);
        Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flow.Id);
        flowSteps.add(dfs3);
        Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env4.Id, env5.Id, flow.Id);
        flowSteps.add(dfs4);
        insert flowSteps;
        System.assertNotEquals(dfs.Id, null);
        System.assertNotEquals(dfs2.Id, null);
        System.assertNotEquals(dfs3.Id, null);
        System.assertNotEquals(dfs4.Id, null);

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        Release__c release = CMTestMethodUtilities.createRelease('Release1');
        release.Project__c = testProject.Id;
        insert release;
        System.assertNotEquals(release.Id, null);

        User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory1');
        userStory.Project__c = testProject.Id;
        userStory.Org_Credential__c = testOrg.Id;
        insert userStory;

        System.assertEquals(testProject.Id, userStory.Project__c);
    }

    @IsTest
    static void saveWithDataManualTask() {
        setupDataDML();
        User_Story__c us = [SELECT Id, Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = 'MyStory1'];
        Deployment_Task__c task = new Deployment_Task__c(
            Name = 'Manual Task',
            Order__c = 1,
            Type__c = 'Manual Task',
            Status__c = 'Draft',
            User_Story__c = us.Id
        );
        insert task;

        Test.setCurrentPage(new PageReference('EditDeploymentTask.Page'));
        System.currentPageReference().getParameters().put('ustryName', us.Name);
        System.currentPageReference()
            .getParameters()
            .put(
                'detail',
                '{"Perform_in_Source_Org":true,"Perform_in_Destination_Orgs":false,"Task_Description":" Test manual step", "Disable_Task_for_Back_Promotions": true}'
            );
        DeploymentTaskExtension ext = new DeploymentTaskExtension(new ApexPages.StandardController(task));

        Test.startTest();

        ext.saveAction();
        task.Perform_Manual_Task__c = 'Before Deployment';
        ext.saveAction();
        System.assertNotEquals(task.dataJson__c, null);
        ext.deleteAction();
        User_Story__c usr = DeploymentTaskExtension.getUserStory(us.Name);
        System.assertEquals(usr.Id, us.Id);
        Test.stopTest();
    }

    @IsTest
    static void saveWithData() {
        setupDataDML();
        User_Story__c us = [SELECT Id, Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = 'MyStory1'];
        Deployment_Task__c task = new Deployment_Task__c(
            Name = 'Data Template',
            Order__c = 1,
            Type__c = 'Data Template',
            Status__c = 'Draft',
            User_Story__c = us.Id,
            DataJSON__c = '{"queryFilterList":[{"order":1,"operatorSet":null,"operator":"e","numberInput":0.0,"isValid":true,"input":"test","finalValue":"Type = \'test\'","fieldType":"PICKLIST","fieldName":"Account Type-Type","fieldLabel":"","dateTimeInput":null,"dateInput":null},{"order":2,"operatorSet":null,"operator":"e","numberInput":0.0,"isValid":true,"input":"true","finalValue":"Active__c = \'true\'","fieldType":"PICKLIST","fieldName":"Active-Active__c","fieldLabel":"","dateTimeInput":null,"dateInput":null}],"filterOverride":true,"filterLogic":" 1 AND 2","dataTemplateName":"TestLabel","dataTemplateId":"a1X1n000004o2jS"}'
        );
        insert task;

        Test.setCurrentPage(new PageReference('EditDeploymentTask.Page'));
        System.currentPageReference().getParameters().put('ustryName', us.Name);
        System.currentPageReference().getParameters().put('detail', '{"dataTemplateName":"TestLabel","dataTemplateId":"a1X1n000004o2jS"}');
        /*System.currentPageReference()
            .getParameters()
            .put('detail', '{"Perform_in_Source_Org":true,"Perform_in_Destination_Orgs":false,"Task_Description":" Test manual step"}');*/
        DeploymentTaskExtension ext = new DeploymentTaskExtension(new ApexPages.StandardController(task));

        Test.startTest();

        ext.saveAction();
        task.Perform_Manual_Task__c = 'Before Deployment';
        ext.saveAction();
        System.assertNotEquals(task.dataJson__c, null);
        ext.deleteAction();
        User_Story__c usr = DeploymentTaskExtension.getUserStory(us.Name);
        System.assertEquals(usr.Id, us.Id);
        Test.stopTest();
    }

    @IsTest
    static void saveWithAttachment() {
        setupDataDML();
        User_Story__c us = [SELECT Id, Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = 'MyStory1'];

        Deployment_Task__c task = new Deployment_Task__c(
            Name = 'Apex Script',
            Order__c = 1,
            Type__c = 'Apex',
            Status__c = 'Draft',
            User_Story__c = us.Id,
            Perform_Manual_Task__c = 'Before Deployment'
        );
        insert task;

        Test.setCurrentPage(new PageReference('EditDeploymentTask.Page'));
        System.currentPageReference().getParameters().put('ustryName', us.Name);
        System.currentPageReference().getParameters().put('detail', 'System.debug(\'this is my test script\');');
        DeploymentTaskExtension ext = new DeploymentTaskExtension(new ApexPages.StandardController(task));

        Test.startTest();
        ext.saveAction();
        System.assertEquals(task.dataJson__c, null);
        System.assertNotEquals([SELECT COUNT() FROM Attachment WHERE ParentId = :task.id], 0);
        Test.stopTest();
    }

    @IsTest
    static void loadBlankSite() {
        setupDataDML();
        User_Story__c us = [SELECT Id, Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = 'MyStory1'];

        Deployment_Task__c task = new Deployment_Task__c(
            Name = 'Apex Script',
            Status__c = 'Draft',
            User_Story__c = us.Id,
            Task_Description__c = 'Description'
        );
        insert task;

        PageReference pageRef = Page.EditDeploymentTask;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('ustryName', us.Name);
        System.currentPageReference().getParameters().put('detail', 'Test Detail');
        new DeploymentTaskExtension(new ApexPages.StandardController(task));
        System.assert(pageRef != null);
    }

    @IsTest
    private static void validateDataTemplate() {
        setupDataDML();
        User_Story__c us = [SELECT Id, Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = 'MyStory1'];
        Deployment_Task__c task = new Deployment_Task__c(
            Name = 'Data Template Test',
            Order__c = 2,
            Type__c = 'Data Template',
            Status__c = 'Draft',
            Perform_Manual_Task__c = 'After Deployment',
            User_Story__c = us.Id
        );
        insert task;

        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        Data_Template__c dataTemplateContact = TestDataFactory.createDataTemplate(
            'Test Contact',
            orgs.get(0).Id,
            'Contact',
            null,
            null,
            null,
            null,
            null
        );

        Test.setCurrentPage(new PageReference('EditDeploymentTask.Page'));
        System.currentPageReference().getParameters().put('ustryName', us.Name);
        System.currentPageReference()
            .getParameters()
            .put('detail', '{"dataTemplateId":"' + dataTemplateContact.Id + '","dataTemplateName":"Test Contact"}');
        DeploymentTaskExtension ext = new DeploymentTaskExtension(new ApexPages.StandardController(task));

        Test.startTest();
        ext.saveAction();
        System.assertEquals(false, ApexPages.hasMessages(), 'Apex Page Message is present, please check');
        System.currentPageReference().getParameters().put('detail', '{"dataTemplateId":"000000000000000","dataTemplateName":"Test Contact"}');
        ext.saveAction();
        System.assertEquals(true, ApexPages.hasMessages(), 'Apex Page Message is not present, please check');
        Test.stopTest();
    }
}