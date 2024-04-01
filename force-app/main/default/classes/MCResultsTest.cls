@SuppressWarnings('PMD')
@isTest
private class MCResultsTest {
    private static final User RUNNING_USER;

    static {
        RUNNING_USER = createRunningUser();
    }

    @TestSetup
    private static void setup() {
        insertData();
    }

    @isTest
    private static void runApexClassCallbackInProgress() {
        // Setup
        assignPermissions(RUNNING_USER.Id);

        Result__c result = [SELECT Id FROM Result__c WHERE Function__r.API_Name__c = 'muleDeploy'];

        // Exercise
        System.runAs(RUNNING_USER) {
            Test.startTest();
            EventBus.publish(
                new MC_Result__e(
                    ResultId__c = result.Id,
                    isFinished__c = false,
                    isSuccess__c = false,
                    Progress_Status__c = 'Job enqueued on the backend'
                )
            );
            Test.stopTest();
        }

        // Verify
        result = [SELECT Status__c, Progress_Status__c FROM Result__c WHERE Id = :result.Id];
        System.assertEquals('In Progress', result.Status__c, 'Status should be updated to in progress.');
        System.assertEquals('Job enqueued on the backend', result.Progress_Status__c, 'Progress Status should be updated by the incoming event.');
    }

    @isTest
    private static void runFlowCallbackOnCompleteWithSuccess() {
        // Setup
        assignPermissions(RUNNING_USER.Id);

        Result__c result = [SELECT Id FROM Result__c WHERE Function__r.API_Name__c = 'herokuDeploy'];

        //Exercise
        System.runAs(RUNNING_USER) {
            Test.startTest();
            EventBus.publish(new MC_Result__e(ResultId__c = result.Id, isFinished__c = true, isSuccess__c = true, Progress_Status__c = 'Completed'));
            FunctionWebEvent.doPost(result.Id, 'Completed', '', '', true, true);
            Test.stopTest();
        }

        // Verify
        result = [SELECT Status__c, Result_Data__c, Progress_Status__c FROM Result__c WHERE Id = :result.Id];
        System.assertEquals('Success', result.Status__c, 'Status should be updated to success.');
        System.assertEquals('callback-executed', result.Result_Data__c, 'Result Data should be updated in the callback flow');
        System.assertEquals('Completed', result.Progress_Status__c, 'Progress Status should be completed.');
    }

    @isTest
    private static void runInvalidApexCallbackOnCompleteWithSuccess() {
        // Setup
        assignPermissions(RUNNING_USER.Id);

        Result__c result = [SELECT Id FROM Result__c WHERE Function__r.API_Name__c = 'muleDeploy'];

        // Exercise
        System.runAs(RUNNING_USER) {
            Test.startTest();
            CallbackHelper.mockCallback = namespacePrefix() + 'VerifyCallbacks';
            EventBus.publish(new MC_Result__e(ResultId__c = result.Id, isFinished__c = true, isSuccess__c = true, Progress_Status__c = 'Completed'));
            FunctionWebEvent.doPost(result.Id, 'Completed', '', '', true, true);
            Test.stopTest();
        }

        // Verify
        result = [SELECT Progress_Status__c, Status__c, Error_Message__c FROM Result__c WHERE Id = :result.Id];
        System.assertEquals('Failed', result.Status__c, 'Status should be updated to failed.');
        System.assertEquals('Error', result.Progress_Status__c, 'Progress Status should be updated to error.');

        String errorMessage = String.format(
            Label.Function_Callback_Failed,
            new List<String>{
                String.format(Label.Callback_not_Found, new List<String>{ 'ApexClass', namespacePrefix() + 'VerifyCallbacks' }) +
                ' ' +
                Label.Callback_not_Found_Information
            }
        );
        System.assertEquals(errorMessage, result.Error_Message__c, 'The error message should point to an invalid callback class.');
    }

    @isTest
    private static void runInvalidFlowCallbackOnCompleteWithSuccess() {
        // Setup
        assignPermissions(RUNNING_USER.Id);

        Result__c result = [SELECT Id FROM Result__c WHERE Function__r.API_Name__c = 'herokuDeploy'];

        // Exercise
        System.runAs(RUNNING_USER) {
            Test.startTest();
            CallbackHelper.mockCallback = 'InvalidFlow';
            EventBus.publish(new MC_Result__e(ResultId__c = result.Id, isFinished__c = true, isSuccess__c = true, Progress_Status__c = 'Completed'));
            FunctionWebEvent.doPost(result.Id, 'Completed', '', '', true, true);
            Test.stopTest();
        }

        // Verify
        result = [SELECT Progress_Status__c, Status__c, Error_Message__c FROM Result__c WHERE Id = :result.Id];
        System.assertEquals('Failed', result.Status__c, 'Status should be updated to failed.');
        System.assertEquals('Error', result.Progress_Status__c, 'Progress Status should be updated to Error');

        String errorMessage = String.format(
            Label.Function_Callback_Failed,
            new List<String>{ String.format(Label.Flow_Callback_Failed, new List<String>{ 'Invalid type: InvalidFlow.' }) }
        );
        System.assert(
            result.Error_Message__c.contains('Flow handler failed with error'),
            'The error message should point to an unknown callback class.'
        );
    }

    // HELPER

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        return users[0];
    }

    private static void assignPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet permissionSet : permissionSets()) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }

    private static List<PermissionSet> permissionSets() {
        return [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
    }

    private static void insertData() {
        List<Function__c> functions = new List<Function__c>();
        Function__c muleDeploy = new Function__c(
            Name = 'muleDeploy',
            API_Name__c = 'muleDeploy',
            Script__c = 'echo "Hello World"',
            Callback_Type__c = 'ApexClass',
            ApexClass__c = namespacePrefix() + 'MCCallbackHandlerTestClass',
            Worker_Size__c = 'XL'
        );
        functions.add(muleDeploy);
        Function__c herokuDeploy = new Function__c(
            Name = 'herokuDeploy',
            API_Name__c = 'herokuDeploy',
            Script__c = 'echo "Hello World"',
            Callback_Type__c = 'Flow',
            FlowHandler__c = namespacePrefix() + 'MCCallbackHandlerTestFlow',
            Worker_Size__c = 'S'
        );
        functions.add(herokuDeploy);
        insert functions;

        List<Result__c> results = new List<Result__c>();
        results.add(
            new Result__c(
                Job_Type__c = 'Integration',
                Start_Time__c = Datetime.now(),
                Status__c = 'In Progress',
                Function__c = muleDeploy.Id,
                Progress_Status__c = 'backend called',
                Function_Worker_Size__c = 'XL'
            )
        );
        results.add(
            new Result__c(
                Job_Type__c = 'Integration',
                Start_Time__c = Datetime.now(),
                Status__c = 'In Progress',
                Function__c = herokuDeploy.Id,
                Progress_Status__c = 'backend called',
                Function_Worker_Size__c = 'S'
            )
        );
        insert results;
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }
}