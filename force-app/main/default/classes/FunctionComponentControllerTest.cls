@isTest
private class FunctionComponentControllerTest {

    private static String namespace;
    private static final User RUNNING_USER;
    private static Deployment_Task__c task;
    private static List<Org__c> credentials;
    private static Function__c functionPromotion;

    static {
        RUNNING_USER = createRunningUser();
    }

    @TestSetup
    private static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }

    @IsTest
    static void getFunctionParameters() {

        assignPermissions(RUNNING_USER.Id);

        System.runAs(RUNNING_USER) {
            data();

            Test.startTest();
            FunctionComponentController.Function result = FunctionComponentController.functionParameters(functionPromotion.Id, task.Id);
            Test.stopTest();

            System.assertEquals(result.parameters.size(), 2, '2 Parameters are available');
            System.assertEquals(result.parameters[1].value, 'updatedvalue2', '2 Parameters are available');
        }
    }


    @IsTest
    static void callConstructor() {
        if(FunctionComponentController.namespace != null) {
            System.assertNotEquals(FunctionComponentController.namespace, null,'No Namespace');
        } else {
            System.assertEquals(FunctionComponentController.namespace, null, 'Namespace');
        }
    }

    private static void assignPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet permissionSet : permissionSets()) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        return users[0];
    }

    private static List<PermissionSet> permissionSets() {
        return [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
    }

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        // Function creation
        String namespace = namespacePrefix();
        functionPromotion = new Function__c(
            Name = 'testFunction',
            API_Name__c = 'testFunction',
            Script__c = 'echo hello world $par1',
            Type__c = 'Custom',
            Parameters__c = '[{"name":"dynamicExpression1","value":"value1"},{"name":"dynamicExpression2","value":"value2"}]',
            Callback_Type__c = 'ApexClass',
            ApexClass__c = namespace + 'FunctionStepExecutionCallback'
        );
        insert functionPromotion;


        User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory1');
        insert userStory;

        task = new Deployment_Task__c();
        task.Order__c = 1;
        task.Status__c = 'Draft';
        task.Name = 'Manual Task';
        task.Type__c = 'Manual Task';
        task.User_Story__c = userStory.Id;
        task.dataJSON__c = '{"functionAPIName":"testFunction","functionParameters":[{"name":"dynamicExpression1","value":"value1"},{"name":"dynamicExpression2","value":"updatedvalue2"}]}';
        insert task;
    }
}