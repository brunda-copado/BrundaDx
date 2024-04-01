@IsTest
private class RunCopadoFunctionTest {
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
            insertData();
        }
    }

    @IsTest
    private static void execute() {
        setHttpMock();
        System.runAs(getUser()) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);

            // Exercise
            Test.startTest();
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'muleDeploy';
            variables.contextId = [SELECT Id FROM Deployment_Job__c LIMIT 1]?.Id;
            variables.parameters = (List<Parameter>) JSON.deserialize(
                [SELECT Parameters__c FROM Function__c LIMIT 1]?.Parameters__c,
                List<Parameter>.class
            );
            variables.optionsJSON = '[{ "name": "volumeSize", "value": "5" }, { "name": "volumeTTL", "value": "3600" }, { "name": "transactionId", "value": "a1f2o00000GOw2OAAT" }]';

            RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });

            List<Result__c> results = [SELECT Id FROM Result__c WHERE Job_Type__c = 'muleDeploy' LIMIT 1];
            Test.stopTest();

            // Verify
            System.assert(!results.isEmpty(), 'Result was not created before executing the function.');
        }
    }

    @IsTest
    private static void trackStandardFunctionCredits() {
        setHttpMock();
        System.runAs(getUser()) {
            // Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');

            FeatureManagement.setPackageIntegerValue('Functions', 1);

            Settings__c setting = new Settings__c();
            setting.Enable_Standard_Function_Edit__c = true;
            setting.SetupOwnerId = UserInfo.getOrganizationId();
            insert setting;

            Test.startTest();
            new Function()
                .name('standardFunction')
                .apiName('standardFunction')
                .script('echo $property')
                .type('Standard')
                .workerSize('M')
                .paramaters('[ {"name" : "property","defaultValue" : "hello"} ]')
                .persist();

            // Exercise
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'standardFunction';
            variables.parameters = (List<Parameter>) JSON.deserialize(
                [SELECT Parameters__c FROM Function__c WHERE Name = :'standardFunction' LIMIT 1]?.Parameters__c,
                List<Parameter>.class
            );
            RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });

            List<Result__c> results = [
                SELECT Id, Status__c, Progress_Status__c, Custom_Function_Used_Minutes__c, CreditSyncStatus__c
                FROM Result__c
                WHERE Job_Type__c = 'standardFunction'
                LIMIT 1
            ];
            Test.stopTest();

            // Verify
            System.assertEquals(false, results.isEmpty(), 'Result is created');
            System.assertEquals('Success', results[0].Status__c, 'Result status is successful.');
            System.assertEquals('Completed', results[0].Progress_Status__c, 'The progress status is completed');
            System.assertNotEquals(null, results[0].Custom_Function_Used_Minutes__c, 'Used minutes for standard function is populated');
            System.assertEquals('Pending', results[0].CreditSyncStatus__c, 'Credit Sync Status is pending');
        }
    }

    @IsTest
    private static void executeWithNoParameters() {
        setHttpMock();
        System.runAs(getUser()) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);

            // Exercise
            Test.startTest();

            new Function().persist();
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'Function_1';
            variables.optionsJSON = '[{ "name": "volumeSize", "value": "5" }, { "name": "volumeTTL", "value": "3600" }, { "name": "transactionId", "value": "a1f2o00000GOw2OAAT" }]';

            RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });

            List<Result__c> results = [SELECT Id FROM Result__c WHERE Job_Type__c = 'Function_1' LIMIT 1];
            Test.stopTest();

            // Verify
            System.assert(!results.isEmpty(), 'Result was not created before executing the function.');
        }
    }

    @IsTest
    private static void executeWithoutContextId() {
        setHttpMock();
        System.runAs(getUser()) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);

            // Exercise
            Test.startTest();
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'muleDeploy';
            variables.contextId = null;
            variables.parameters = (List<Parameter>) JSON.deserialize(
                [SELECT Parameters__c FROM Function__c LIMIT 1]?.Parameters__c,
                List<Parameter>.class
            );
            variables.optionsJSON = '[{ "name": "volumeSize", "value": "5" }, { "name": "volumeTTL", "value": "3600" }, { "name": "transactionId", "value": "a1f2o00000GOw2OAAT" }]';

            RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });

            List<Result__c> results = [SELECT Id FROM Result__c WHERE Job_Type__c = 'muleDeploy' LIMIT 1];
            Test.stopTest();

            // Verify
            System.assert(!results.isEmpty(), 'Result was not created before executing the function.');
        }
    }

    @IsTest
    private static void executeWithError() {
        setHttpMock();
        User user = getUser();
        System.runAs(user) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);

            // Exercise
            Test.startTest();
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'unknown';
            variables.contextId = [SELECT Id FROM Deployment_Job__c LIMIT 1]?.Id;
            variables.showValidationErrors = true;

            Exception result;

            try {
                RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });
            } catch (Exception ex) {
                result = ex;
            }
            Test.stopTest();

            // Verify
            System.assert(
                result.getMessage().contains(Label.Function_not_Found),
                'The error should come from a non-existing function in the system.'
            );
        }
    }

    @IsTest
    private static void executeWithParallelLimit() {
        Exception expectedException = null;
        setHttpMock();

        User user = getUser();
        System.runAs(user) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);
            FeatureManagement.setPackageIntegerValue('Function_Parallel_Limit', 0);

            // Exercise
            Test.startTest();
            RunCopadoFunction.InvocableVariables variables = new RunCopadoFunction.InvocableVariables();
            variables.functionApiName = 'muleDeploy';
            variables.contextId = [SELECT Id FROM Deployment_Job__c LIMIT 1]?.Id;
            variables.showValidationErrors = true;

            try {
                RunCopadoFunction.execute(new List<RunCopadoFunction.InvocableVariables>{ variables });
            } catch (CopadoFunctionException ex) {
                expectedException = ex;
            }

            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'There is an exception.');
        }
    }

    @IsTest
    private static void payloadWithOptions() {
        // Setup
        Function__c function = getFunction();
        String volumeOptions = '[{ "name": "volumeSize", "value": "5" }, { "name": "volumeTTL", "value": "3600" }, { "name": "transactionId", "value": "a1f2o00000GOw2OAAT" }]';

        // Exercise
        Test.startTest();
        FunctionPayload payload = new FunctionPayload(function)
            .parameters((List<Parameter>) JSON.deserialize(function.Parameters__c, List<Parameter>.class))
            .options((List<Parameter>) JSON.deserialize(volumeOptions, List<Parameter>.class));
        Test.stopTest();

        // Verify
        String result = payload.toJson();
        System.assert(result.contains('branchName'), 'branchName parameter was not added to the payload options.');
        System.assert(result.contains('transactionId'), 'transactionId parameter was not added to the payload options.');
        System.assert(result.contains('volumeSize'), 'volumeSize parameter was not added to the payload options.');
        System.assert(result.contains('volumeTTL'), 'volumeTTL parameter was not added to the payload options.');
    }

    @IsTest
    private static void payloadWithoutDomainAndDefaultDomain() {
        // Setup
        Exception expectedException = null;
        Function__c function = getFunction();
        function.Image_Name__c = null;

        // Exercise
        try {
            new FunctionPayload(function);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        String expectedError = String.format(Label.FunctionImageDomainNotFound, new List<String>{ function.API_Name__c });
        System.assertNotEquals(null, expectedException, 'There is an exception');
        System.assertEquals(expectedError, expectedException.getMessage(), 'The exception message matches');
    }

    @IsTest
    private static void payloadWithoutDomain() {
        // Setup
        Function__c function = getFunction();
        function.Image_Name__c = 'http://us.gcr.io/copado/relativePath';

        // Exercise
        FunctionPayload payload = new FunctionPayload(function);

        // Verify
        System.assertEquals('http://us.gcr.io/copado/relativePath', payload.image, 'The image value matches');
    }

    @IsTest
    private static void processResponseForSuccessFunctionCallout() {
        setHttpMock();
        User user = getUser();
        System.runAs(user) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);
            Result__c result = (Result__c) new Result().status('Not Started').persist();
            Function__c function = getFunction();

            List<Parameter> parameters = (List<Parameter>) JSON.deserialize(function.Parameters__c, List<Parameter>.class);
            List<Parameter> options = (List<Parameter>) JSON.deserialize(function.Options__c, List<Parameter>.class);

            String payload = new FunctionPayload(function).parameters(parameters).options(options).resultId(result.Id).toJson();

            // Exercise
            Test.startTest();
            new FunctionCallout(result.Id)
                .isStandard(function.Type__c == 'Standard')
                .payload(payload)
                .apiKey(new Settings().mySettings.API_Key__c)
                .build()
                .request()
                .parseResponse();
            Test.stopTest();

            // Verify
            result = [SELECT Status__c FROM Result__c LIMIT 1];
            Assert.areEqual('In Progress', result.Status__c, 'Result should be in progress');
        }
    }

    @IsTest
    private static void processResponseForErrorFunctionCallout() {
        setErrorHttpMock();
        User user = getUser();
        System.runAs(user) {
            // Setup
            FeatureManagement.setPackageIntegerValue('Functions', 1);
            Result__c result = (Result__c) new Result().status('Not Started').persist();
            Function__c function = getFunction();

            List<Parameter> parameters = (List<Parameter>) JSON.deserialize(function.Parameters__c, List<Parameter>.class);
            List<Parameter> options = (List<Parameter>) JSON.deserialize(function.Options__c, List<Parameter>.class);

            String payload = new FunctionPayload(function).parameters(parameters).options(options).resultId(result.Id).toJson();

            // Exercise
            Test.startTest();
            new FunctionCallout(result.Id)
                .isStandard(function.Type__c == 'Standard')
                .payload(payload)
                .apiKey(new Settings().mySettings.API_Key__c)
                .build()
                .request()
                .parseResponse();
            Test.stopTest();

            // Verify
            result = [SELECT Status__c FROM Result__c LIMIT 1];
            Assert.areEqual('Failed', result.Status__c, 'Result should be failed');
        }
    }

    // Helpers

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Function__c getFunction() {
        return [
            SELECT API_Name__c, Script__c, Image_Name__c, Parameters__c, Options__c, Worker_Size__c, Timeout__c, Type__c
            FROM Function__c
            WHERE API_Name__c = 'muleDeploy'
            LIMIT 1
        ];
    }

    private static void insertData() {
        insert new Personal_Settings__c(SetupOwnerId = UserInfo.getUserId(), API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

        Credential env1Credential = new Credential();
        Credential env2Credential = new Credential();
        Environment env1 = new Environment().name('DEV-1').type('Production/Developer').platform('Salesforce').add(env1Credential);
        Environment env2 = new Environment().name('INT').type('Production/Developer').platform('Salesforce').add(env2Credential);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Salesforce')
            .add(new Connection(env1, env2).branch('Source'))
            .add(new Project().add(new UserStory().credential(env1Credential)));

        new Function()
            .name('muleDeploy')
            .apiName('muleDeploy')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{$Source.Property.DBName}", "required": true},' +
                    '{"name": "DestinationDBProvider", "defaultValue": "{$Destination.Property.DB-Provider}", "required": true},' +
                    '{"name": "PipelineUsername", "defaultValue": "{$Pipeline.Property.Username}", "required": true},' +
                    '{"name": "UserEmail", "defaultValue": "{$User.Property.Email}", "required": true},' +
                    '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                    '{"name": "gitUsername", "value": "", "sensitive": true},' +
                    '{"name": "gitPassword", "value": "", "sensitive": true},' +
                    '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .image('http://us.gcr.io/copado-backend-functions')
            .timeout(5)
            .persist();

        Promotion promotion = new Promotion(new Release(), new Credential(), new Credential());
        promotion.persist();

        Function__c function = [SELECT Id FROM Function__c WHERE Name = 'muleDeploy' LIMIT 1];

        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).disableAll();
        Deployment__c deployment = (Deployment__c) new Deployment(promotion)
            .name('Deployment')
            .add(
                new Step()
                    .name('Step 1')
                    .order(1)
                    .type('Function')
                    .status('In Progress')
                    .dataJson(
                        '{"functionId":"' +
                            function.Id +
                            '","functionAPIName":"' +
                            'muleDeploy' +
                            '","functionParameters":' +
                            '[{"name": "SourceDBName", "value": "dbname"},' +
                            '{"name": "DestinationDBProvider", "value": "provider"},' +
                            '{"name": "PipelineUsername", "value": "username"},' +
                            '{"name": "UserEmail", "value": "email"},' +
                            '{"name": "LogLevel", "value": "ERROR"}]}'
                    )
            )
            .persist();
        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).enableAll();

        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).disableAll();
        Destination_Org__c destination = new Destination_Org__c(
            Deployment__c = deployment.Id,
            Status__c = 'In progress',
            To_Org__c = [SELECT Id FROM Org__c LIMIT 1]
            .Id
        );
        insert destination;
        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).enableAll();

        List<Step__c> steps = [SELECT Id FROM Step__c];
        insert new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destination.Id);

        new SystemProperty().apiName('DBName').value('OracleDB').parent([SELECT Id FROM Environment__c WHERE Name = 'DEV-1' LIMIT 1].Id);
        new SystemProperty().apiName('DB-Provider').value('OracleDB').parent([SELECT Id FROM Environment__c WHERE Name = 'INT' LIMIT 1].Id);
        new SystemProperty().apiName('Username').value('user@oracledb.com').parent([SELECT Id FROM Deployment_Flow__c LIMIT 1].Id);
        new SystemProperty().apiName('Email').value('user@example.com').parent(UserInfo.getUserId()).persist();
    }

    private static void setHttpMock() {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"id": "123123123", "status": "pending", "messages": ["function received and Queued", "execution will start shortly"]}',
            null
        );
        Test.setMock(HttpCalloutMock.class, mockResponse);
    }

    private static void setErrorHttpMock() {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
            400,
            'Not Complete',
            '{"id": "123123123", "status": "pending", "messages": ["function not received and Queued", "execution will not start"]}',
            null
        );
        Test.setMock(HttpCalloutMock.class, mockResponse);
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }
}