@IsTest
private class FunctionExecutionServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }

    @IsTest
    private static void exceptionWithNoName() {
        System.runAs(getUser()) {
            // Setup

            Exception expectedException;
            CopadoFunctions.ExecuteResponse expectedResult;
            CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
            request.callback = 'MC_MockName';

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoFunctions.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Missing required parameters : Function API Name', expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void executeFunctionWithoutContextId() {
        User user = getUser();
        System.runAs(user) {
            // Setup

            CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
            request.functionApiName = 'customFunction';
            request.parameters = getParams();
            request.callback = namespacePrefix() + 'FunctionStepExecutionCallback';

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');

            // Exercise

            Test.startTest();
            CopadoFunctions.ExecuteResponse expectedResult = CopadoFunctions.execute(request);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.result, 'Result is not null');
            System.assertEquals('Success', expectedResult.result.Status__c, 'Result status is successful.');
            System.assertEquals('Completed', expectedResult.result.Progress_Status__c, 'The progress status is completed');
            System.assertEquals(null, expectedResult.result.JobStep__c, 'Job Step doesn\'t exist.');
        }
    }

    @IsTest
    private static void executeFunctionSuccessfully() {
        User user = getUser();
        System.runAs(user) {
            // Setup

            CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
            request.functionApiName = 'customFunction';
            request.contextId = user.Id;
            request.parameters = getParams();
            request.callback = namespacePrefix() + 'FunctionStepExecutionCallback';

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');

            // Exercise

            Test.startTest();
            CopadoFunctions.ExecuteResponse expectedResult = CopadoFunctions.execute(request);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.result, 'Result is not null');
            System.assertEquals('Success', expectedResult.result.Status__c, 'Result status is successful.');
            System.assertEquals('Completed', expectedResult.result.Progress_Status__c, 'The progress status is completed');
            System.assertEquals(null, expectedResult.result.JobStep__c, 'Job Step doesn\'t exist.');
        }
    }

    @IsTest
    private static void executeWithIncorrectFunctionName() {
        User user = getUser();
        System.runAs(user) {
            // Setup

            CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
            request.functionApiName = 'Function1';
            request.contextId = user.Id;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');

            // Exercise

            Test.startTest();
            CopadoFunctions.ExecuteResponse expectedResult = CopadoFunctions.execute(request);
            Test.stopTest();

            // Verify

            String errorMessage = Label.Function_not_Found + ' Function1';
            System.assertNotEquals(null, expectedResult.result, 'Result is not null');
            System.assertEquals('Failed', expectedResult.result.Status__c, 'Result status is failed.');
            System.assert(expectedResult.result.Error_Message__c.contains(errorMessage), 'Result\'s error message contains the given text.');
        }
    }

    @IsTest
    private static void executeFunctionWithErrors() {
        System.runAs(getUser()) {
            // Setup

            CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
            request.functionApiName = 'customFunction';
            request.contextId = [SELECT Id FROM JobStep__c LIMIT 1].Id;
            request.parameters = getParams();
            request.callback = namespacePrefix() + 'FunctionStepExecutionCallback';
            request.options = getOptions();

            FunctionEngine.mockResponse = functionCompletionEvent(false, 'Custom error', '');

            // Exercise

            Test.startTest();
            CopadoFunctions.ExecuteResponse expectedResult = CopadoFunctions.execute(request);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult.result, 'Result is not null');
            System.assertEquals('Failed', expectedResult.result.Status__c, 'Result status is Error.');
            System.assertEquals('Completed', expectedResult.result.Progress_Status__c, 'The progress status is Error');
            System.assertNotEquals(null, expectedResult.result.JobStep__c, 'Job step is populated');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        new Org__c(
            Oauth_Signature__c = 'Valid',
            Validated_Date__c = System.today(),
            Username__c = UserInfo.getUserName(),
            SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId()
        );

        new JobExecution().status('Not Started').add(new JobStep().name('S2').add(new Result().status('Not Started')));

        String namespace = namespacePrefix();
        new Function()
            .name('customFunction')
            .apiName('customFunction')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                '{"name": "gitUsername", "value": "", "sensitive": true},' +
                '{"name": "gitPassword", "value": "", "sensitive": true},' +
                '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback')
            .persist();
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }

    private static List<CopadoFunctions.FunctionParameter> getParams() {
        List<CopadoFunctions.FunctionParameter> result = new List<CopadoFunctions.FunctionParameter>();

        result.add(new CopadoFunctions.FunctionParameter('SourceDBName', '{!$Source.Property.DBName}').required(true));
        result.add(new CopadoFunctions.FunctionParameter('DestinationDBProvider', '{!$Destination.Property.DB-Provider}'));
        result.add(new CopadoFunctions.FunctionParameter('PipelineUsername', '{!$Pipeline.Property.Username}'));
        result.add(new CopadoFunctions.FunctionParameter('UserEmail', '{!$User.Property.Email}'));
        result.add(new CopadoFunctions.FunctionParameter('LogLevel', 'ERROR'));

        return result;
    }

    private static List<CopadoFunctions.FunctionParameter> getOptions() {
        List<CopadoFunctions.FunctionParameter> result = new List<CopadoFunctions.FunctionParameter>();

        result.add(new CopadoFunctions.FunctionParameter('gitUrl', 'xxxxxx').required(true));
        result.add(new CopadoFunctions.FunctionParameter('gitUsername', '').sensitive(true));
        result.add(new CopadoFunctions.FunctionParameter('gitPassword', '').required(true));
        result.add(new CopadoFunctions.FunctionParameter('branchName', '').sensitive(true));

        return result;
    }
}