@IsTest
private class DynamicExpressionEvaluateServiceImplTest {
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
            createDeploymentJob();
        }
    }


    @IsTest
    private static void executeWithoutRequiredParams() {
        // Setup
        Exception expectedException;

        // Exercise
        Test.startTest();
        try {
            Jobs.DynamicExpression.evaluate(new Jobs.DynamicExpressionEvaluateRequest(null, new List<String>()));
        } catch(Exception ex) {
            expectedException = ex;
        }
        Test.stopTest();

        // Verify
        Assert.areNotEqual(null, expectedException, 'An exception should be thrown.');
        Assert.areEqual('Missing required parameters : Dynamic Expressions', expectedException.getMessage(), 'Exception messages match.');
    }


    @IsTest
    private static void parseWithInvalidDynamicExpression() {
        // Setup
        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(null, new List<String> {'{$Invalid.Expression}'});

        // Exercise
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);

        // Verify
        String message = Label.InValidExpression + '{$Invalid.Expression}';
        Assert.areEqual(1, result.size(), 'The result size matches');
        Assert.areEqual(message, result[0].errorMessage, 'Exception messages match.');
    }

    @IsTest
    private static void parseHardCodedValues() {
        // Setup
        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('value');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(null, dynamicExpressions);

        // Exercise
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);

        // Verify
        Assert.areEqual(1, result.size(), 'The result size matches');
        Assert.areEqual('value', result[0].value, 'Value matches');
    }


    @IsTest
    private static void parseUserTemplate() {
        // Setup
        String firstNamePattern = UserInfo.getFirstName() + '*';
        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$User.Name}');
        dynamicExpressions.add('{$User.Name.matches("'+ firstNamePattern + '")}');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(null, dynamicExpressions);

        // Exercise
        Test.startTest();
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
        Test.stopTest();

        // Verify
        Assert.areEqual(2, result.size(), 'There are 2 parameter values in the result.');

        Assert.areEqual(UserInfo.getName(), result[0].value, 'The values match.');
        Assert.areEqual('true', result[1].value, 'The values match.');
        Assert.areEqual(false, result[0].isSensitive, 'Parameter isn\'t sensitive');
        Assert.areEqual(false, result[1].isSensitive, 'Parameter isn\'t sensitive');
    }


    @IsTest
    private static void parseSourceTemplateWithInValidField() {
        // Setup
        Exception expectedException = null;
        Deployment_Job__c job = [SELECT Id FROM Deployment_Job__c LIMIT 1];

        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$Source.InvalidField}');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(job.Id, dynamicExpressions);

        // Exercise
        try {
            Jobs.DynamicExpression.evaluate(request);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        String message = 'No such column \'InvalidField\' on entity';
        Assert.areNotEqual(null, expectedException, 'There is some exception');
        System.assert(expectedException.getMessage().contains(message), 'There is an error in parsing the expression');
    }


    @IsTest
    private static void parseSourceTemplateWithInSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

        new SystemProperty()
            .value('sql server')
            .apiName('DB')
            .sensitive(false)
            .parent(job.Source_Id__c)
            .persist();

        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$Source.Property.DB}');
        dynamicExpressions.add('{$Source.Property.DB.matches(sql*)}');
        dynamicExpressions.add('{$Source.Property.DB.matches(nosql*)}');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(job.Id, dynamicExpressions);

        // Exercise
        Test.startTest();
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
        Test.stopTest();

        // Verify
        Assert.areEqual(3, result.size(), 'There are 3 dynamic expression values in the result.');
        Assert.areEqual('sql server', result[0].value, 'The value matches.');
        Assert.areEqual('true', result[1].value, 'The value matches.');
        Assert.areEqual('false', result[2].value, 'The value matches.');
        Assert.areEqual(false, result[0].isSensitive, 'Parameter isn\'t sensitive');
        Assert.areEqual(false, result[1].isSensitive, 'Parameter isn\'t sensitive');
        Assert.areEqual(false, result[2].isSensitive, 'Parameter isn\'t sensitive');
    }


    @IsTest
    private static void parseMixedTemplateWithSensitiveValue() {
        // Setup
        Deployment_Job__c job = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c LIMIT 1];
        Test.setMock(WebServiceMock.class, new MdApiMock());

        new SystemProperty()
            .value('source/sql')
            .apiName('SourceDB')
            .sensitive(true)
            .parent(job.Source_Id__c);
        new SystemProperty()
            .value('destination/sql')
            .apiName('DestinationDB')
            .sensitive(true)
            .parent(job.Destination_Id__c);
        new SystemProperty()
            .value('pipeline/sql')
            .apiName('PipelineDB')
            .sensitive(true)
            .parent(job.Pipeline_Id__c);
        new SystemProperty()
            .value('user/sql')
            .apiName('UserDB')
            .sensitive(true)
            .parent(UserInfo.getUserId())
            .persist();

        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$Source.Property.SourceDB}');
        dynamicExpressions.add('{$Destination.Property.DestinationDB}');
        dynamicExpressions.add('{$Pipeline.Property.PipelineDB}');
        dynamicExpressions.add('{$User.Property.UserDB}');
        dynamicExpressions.add('hardcodedValue');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(job.Id, dynamicExpressions);

        // Exercise
        Test.startTest();
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
        Test.stopTest();

        // Verify
        Assert.areEqual(5, result.size(), 'There are 5 expressions the result');
        Assert.areEqual('source/sql', result[0].value, 'The value matches.');
        Assert.areEqual(true, result[0].isSensitive, 'Parameter is sensitive');

        Assert.areEqual('destination/sql', result[1].value, 'The value matches.');
        Assert.areEqual(true, result[1].isSensitive, 'Parameter is sensitive');

        Assert.areEqual('pipeline/sql', result[2].value, 'The value matches.');
        Assert.areEqual(true, result[2].isSensitive, 'Parameter is sensitive');

        Assert.areEqual('user/sql', result[3].value, 'The value matches.');
        Assert.areEqual(true, result[3].isSensitive, 'Parameter is sensitive');

        Assert.areEqual('hardcodedValue', result[4].value, 'The value matches.');
        Assert.areEqual(false, result[4].isSensitive, 'Parameter is sensitive');
    }


    @IsTest
    private static void parseSObjectExpression() {
        //Setup
        Account parentAccount = new Account();
        parentAccount.Name = 'Parent Account';
        insert parentAccount;

        Account account = new Account();
        account.ParentId = parentAccount.Id;
        account.Name = 'Child Account';
        insert account;

        Contact c = new Contact();
        c.LastName = 'Contact';
        c.AccountId = account.Id;
        insert c;

        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$Context.LastName}');
        dynamicExpressions.add('{$Context.LastName.matches(Cont*)}');
        dynamicExpressions.add('{$Context.Account.Name}');
        dynamicExpressions.add('{$Context.Account.Name.matches(Child*)}');
        dynamicExpressions.add('{$Context.Account.Parent.Name}');
        dynamicExpressions.add('{$Context.Account.Parent.Name.matches(Parent*)}');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(c.Id, dynamicExpressions);

        // Exercise
        Test.startTest();
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
        Test.stopTest();

        // Verify
        Assert.areEqual(6, result.size(), 'There are 6 dynamic expression values in the result.');
        Assert.areEqual('Contact', result[0].value, 'The values match.');
        Assert.areEqual('true', result[1].value, 'The values match.');
        Assert.areEqual('Child Account', result[2].value, 'The values match.');
        Assert.areEqual('true', result[3].value, 'The values match.');
        Assert.areEqual('Parent Account', result[4].value, 'The values match.');
        Assert.areEqual('true', result[5].value, 'The values match.');
    }


    @IsTest
    private static void parseSSHRepositoryWithoutRepositoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            Test.startTest();
            // Setup
            Git_Repository__c repository = sshRepository();
            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Context.Repository.Credential}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(repository.Id, dynamicExpressions);

            // Exercise
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size(), 'The expression count matches');
            Assert.areEqual(true, result[0].isSensitive, 'Parameter is sensitive');
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url, 'The url matches');
            Assert.areEqual('ssh', gitCredential.type, 'Credential type matches');
            Assert.areEqual('publicKey', gitCredential.publicKey, 'Key matches');
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey, 'Key content matches');
        }
    }


    @IsTest
    private static void parseRepositoryWithUserStoryId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            // Setup
            Test.startTest();
            Git_Repository__c repository = sshRepository();

            Deployment_Flow__c pipeline = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c LIMIT 1];
            pipeline.Git_Repository__c = repository.Id;

            update pipeline;
            
            Id userStoryId = [SELECT Id from User_Story__c LIMIT 1].Id;
            
            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Context.Repository.Credential}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(userStoryId, dynamicExpressions);

            // Exercise
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            RepositoryExpression.Credential gitCredential = (RepositoryExpression.Credential) JSON.deserialize(
                result[0].value,
                RepositoryExpression.Credential.class
            );
            Assert.areEqual(1, result.size(), 'The expression count matches');
            Assert.areEqual(true, result[0].isSensitive, 'Parameter is sensitive');
            Assert.areEqual('git@github.com:user/repository.git', gitCredential.url, 'The url matches');
            Assert.areEqual('ssh', gitCredential.type, 'Credential type matches');
            Assert.areEqual('publicKey', gitCredential.publicKey, 'Key matches');
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', gitCredential.privateKey, 'Key content matches');
        }
    }


    @IsTest
    private static void parseSObjectExpressionWithExecutionParent() {
        User copadoUser = getUser();

        Test.startTest();
        System.runAs(copadoUser) {

            // Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .add(new JobStep()
                    .name('Step 1')
                    .type('Manual')
                    .order(1)
                    .configJson('')).persist();

            JobStep__c step = [SELECT Id FROM JobStep__c WHERE Name = 'Step 1'];

            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Job.ExecutionParent.Name}');
            dynamicExpressions.add('{$Job.ExecutionParent.Name.matches(Test Dev*)}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(step.Id, dynamicExpressions);

            // Exercise
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size(), 'There are 2 values in the result');
            Assert.areEqual('Test Dev 1', result[0].value, 'The values match');
            Assert.areEqual('true', result[1].value, 'The values match');
        }
    }


    @IsTest
    private static void parseStepExpressionWithInvalidField() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            //Setup
            Exception expectedException = null;
            Step__c step = [SELECT Id from Step__c WHERE Order__c = 2 LIMIT 1];

            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Context.PrevStep.InValidFied}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(step.Id, dynamicExpressions);

            // Exercise
            try{
                Jobs.DynamicExpression.evaluate(request);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            String message = 'Didn\'t understand relationship \'PrevStep\' in field path';
            Assert.areNotEqual(null, expectedException, 'There is an exception');
            System.assert(expectedException.getMessage().contains(message), 'There is an error in parsing the expression');
        }
    }


    @IsTest
    private static void parseFirstStepExpression() {
        User copadoUser = getUser();
        Test.startTest();
        System.runAs(copadoUser) {

            // Setup
            List<Step__c> steps = [SELECT Id, Branch__c, JsonResult__c FROM Step__c ORDER BY Order__c DESC];
            steps[1].Branch__c = 'main';
            steps[1].JsonResult__c = '{ "user_stories": ["US-0001","US-0003"], "count": 2, "target_brach": "main", "promotion_brach":"release/v1.0", "user": {"name": "logedInUser"} }';
            update steps[1];

            Destination_Org__c destinationOrg = [SELECT Id FROM Destination_Org__c LIMIT 1];

            Deployment_Job__c firstJob = new Deployment_Job__c(Step__c = steps[1].Id, Destination_Org__c = destinationOrg.Id);
            insert firstJob;

            Deployment_Job__c secondJob = new Deployment_Job__c(Step__c = steps[0].Id, Destination_Org__c = destinationOrg.Id);
            insert secondJob;

            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Job.FirstStep.Branch__c}');
            dynamicExpressions.add('{$Job.FirstStep.Branch__c.matches("main")}');
            dynamicExpressions.add('{$Job.FirstStep.Deployment__r.Description__c}');
            dynamicExpressions.add('{$Job.FirstStep.Deployment__r.Description__c.matches("Sample*")}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user_stories}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.promotion_brach.matches(release*)}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.count}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.count.matches(2)}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.name}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.name.matches("logedIn*")}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.target_brach}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.target_brach.matches("something")}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.invalidProperty}');
            dynamicExpressions.add('{$Job.FirstStep.JSONResult.user.invalidProperty.matches("nothing")}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(secondJob.Id, dynamicExpressions);

            // Exercise
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(14, result.size(), 'The expression count matches');
            Assert.areEqual('main', result[0].value, 'The values match');
            Assert.areEqual('true', result[1].value, 'The values match');

            Assert.areEqual('Sample Deployment', result[2].value, 'The values match');
            Assert.areEqual('true', result[3].value, 'The values match');
            Assert.areEqual('["US-0001","US-0003"]', result[4].value, 'The values match');
            Assert.areEqual('true', result[5].value, 'The values match');

            Assert.areEqual('2', result[6].value, 'The values match');
            Assert.areEqual('true', result[7].value, 'The values match');

            Assert.areEqual('logedInUser', result[8].value, 'The values match');
            Assert.areEqual('true', result[9].value, 'The values match');

            Assert.areEqual(null, result[10].value, 'The values match');
            Assert.areEqual('false', result[11].value, 'The values match');

            Assert.areEqual(null, result[12].value, 'The values match');
            Assert.areEqual('false', result[13].value, 'The values match');
        }
    }


    @IsTest
    private static void parseOrgCredentialWithJobContextId() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            // Setup
            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            Deployment_Job__c job = [SELECT Id, Source_Id__c FROM Deployment_Job__c LIMIT 1];

            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Source.Credential.SessionId}');
            dynamicExpressions.add('{$Destination.Credential.Endpoint}');

            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(job.Id, dynamicExpressions);

            // Exercise
            Test.startTest();
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size(), 'The expression count matches');
            Assert.areEqual(true, result[0].isSensitive, 'The expression is sensitive');
            Assert.areEqual(true, result[1].isSensitive, 'The expression is sensitive');
            Assert.areEqual('sessionId', result[0].value, 'The values match');
            Assert.areEqual('https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW', result[1].value, 'The values match');
        }
    }

    @IsTest
    private static void parseOrgCredentialsWithOrgID() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            // Setup
            Test.setMock(HttpCalloutMock.class, new WebHookMock());
            Org__c org = [SELECT Id FROM Org__c LIMIT 1];

            insert new Personal_Settings__c(SetupOwnerId = copadoUser.Id, API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999'));

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(
                org.Id,
                new List<String>{ '{$Context.Credential.Endpoint}', '{$Context.Credential.SessionId}' }
            );

            // Exercise
            Test.startTest();
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(2, result.size(), 'The expression count matches');
            Assert.areEqual(true, result[0].isSensitive, 'The expression is sensitive');
            Assert.areEqual(true, result[1].isSensitive, 'The expression is sensitive');
            Assert.areEqual('https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW', result[0].value, 'The values match');
        }
    }


    @IsTest
    private static void parseSObjectExpressionWithJsonFields() {
        User copadoUser = getUser();
        System.runAs(copadoUser) {

            //Setup
            Deployment__c deployment = [SELECT Id FROM Deployment__c LIMIT 1];

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Test.startTest();
            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .deployment(deployment.Id)
                .dataJson('{ "key1": "value1", "nested": { "key2": "value2.1" }, "key3": ["US-0001","US-0003"], "key4": null }')
                .add(new JobStep()
                    .name('Step 1')
                    .type('Manual')
                    .order(1)
                    .configJson('')).persist();

            JobStep__c step = [SELECT Id, Source_Id__c FROM JobStep__c WHERE Name = 'Step 1'];

            List<String> dynamicExpressions = new List<String>();
            dynamicExpressions.add('{$Context.JobExecution__r.DataJson.key1}');
            dynamicExpressions.add('{$Context.JobExecution__r.DataJson.nested.key2}');
            dynamicExpressions.add('{$Context.JobExecution__r.DataJson.key3}');
            dynamicExpressions.add('{$Context.JobExecution__r.DataJson.key4}');

            Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(step.Id, dynamicExpressions);

            // Exercise
            List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(4, result.size(), 'The expression count matches');
            Assert.areEqual('value1', result[0].value, 'The values match');
            Assert.areEqual('value2.1', result[1].value, 'The values match');
            Assert.areEqual('["US-0001","US-0003"]', result[2].value, 'The values match');
            Assert.areEqual(null, result[3].value, 'The values match');
        }
    }


    @IsTest
    private static void parseApexExpressionWithInvalidClass() {
        //Setup
        List<String> dynamicExpressions = new List<String>();
        dynamicExpressions.add('{$Context.Apex.InValidClass}');

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(UserInfo.getUserId(), dynamicExpressions);

        // Exercise
        List<Jobs.DynamicExpressionEvaluateResult> result = Jobs.DynamicExpression.evaluate(request);

        // Verify
        System.assert(result[0].errorMessage.contains(Label.InvalidExpressionClass + 'InValidClass'), 'Result contains the error message');
    }


    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }


    private static void createDeploymentJob() {
        Credential env1Credential = new Credential();
        Credential env2Credential = new Credential();
        Environment env1 = new Environment()
            .name('Environment 1')
            .type('Production/Developer')
            .platform('Salesforce')
            .add(env1Credential);
        Environment env2 = new Environment()
            .name('Environment 2')
            .type('Production/Developer')
            .platform('Salesforce')
            .add(env2Credential);
        Environment env3 = new Environment()
            .name('Environment 3')
            .type('Production/Developer')
            .platform('Salesforce')
            .add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Salesforce')
            .add(new Connection(env1, env2).branch('Source'))
            .add(new Connection(env2, env3).branch('Destination'))
            .add(new Project().add(new UserStory().credential(env1Credential)))
            .persist();

        Promotion promotion = new Promotion(new Release(), new Credential(), new Credential());
        promotion.persist();

        Deployment__c deployment = (Deployment__c) new Deployment(promotion)
            .name('Test Dev 1')
            .description('Sample Deployment')
            .add(new Step()
                .name('Step 1')
                .order(1))
            .add(new Step()
                .name('Step 2')
                .order(2))
            .persist();

        Destination_Org__c destination = new Destination_Org__c(
                                                Deployment__c = deployment.Id,
                                                To_Org__c = [SELECT Id FROM Org__c LIMIT 1].Id);
        insert destination;

        List<Step__c> steps = [SELECT Id FROM Step__c];
        insert new Deployment_Job__c(
            Step__c = steps[0].Id,
            Destination_Org__c = destination.Id
        );
    }


    private static Git_Repository__c sshRepository() {
        Git_Repository__c result = (Git_Repository__c) new Repository()
                                                                .name('gitRepository')
                                                                .uri('git@github.com:user/repository.git')
                                                                .persist();

        Attachment attachment1 = new Attachment(
            Name = 'id_rsa.pub',
            Body = Blob.valueOf('publicKey'),
            ParentId = result.Id
        );
        Attachment attachment2 = new Attachment(
            Name = 'id_rsa',
            Body = Blob.valueOf('-----BEGIN PRIVATE KEY-----privateKey'),
            ParentId = result.Id
        );
        insert new List<Attachment>{ attachment1, attachment2 };

        return result;
    }


    // INNER

    private class MdApiMock implements WebServiceMock {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType
        ) {
            response.put('response_x', createResponse());
        }

        private MetadataService.createMetadataResponse_element createResponse() {
            MetadataService.createMetadataResponse_element responseElement = new MetadataService.createMetadataResponse_element();
            MetadataService.SaveResult sr = new MetadataService.SaveResult();
            sr.success = true;

            responseElement.result = new List<MetadataService.SaveResult>{ sr };

            return responseElement;
        }
    }


    public class WebHookMock implements HttpCalloutMock {
        private Integer statusCode = 200;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public WebHookMock() {
        }

        public WebHookMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{ "isSuccess": true, "sessionId": "sessionId", "endPoint": "https://copadodev.salesforce.com/services/Soap/u/49.0/00D09000007GB3WEAW" }'
            );
            res.setStatusCode(statusCode);

            return res;
        }
    }
}